#
# Cookbook Name:: couchbase
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

rightscale_marker :begin

couchbase_edition = node[:db_couchbase][:edition]
couchbase_version = "2.2.0"

couchbase_package = value_for_platform(
  ["centos", "redhat", "suse", "fedora" ] => {
    "default" => "couchbase-server-#{couchbase_edition}_#{couchbase_version}_x86_64.rpm"
  },
  ["ubuntu", "debian"] => {
    "default" => "couchbase-server-#{couchbase_edition}_#{couchbase_version}_x86_64.deb"
  }
)

log "downloading #{couchbase_package}"

if not File.exists?("/tmp/#{couchbase_package}")
  remote_file "/tmp/#{couchbase_package}" do
    source "http://packages.couchbase.com/releases/#{couchbase_version}/#{couchbase_package}"
    mode "0644"
  end
end

log "installing #{couchbase_package}"

package "couchbase-server" do
  source "/tmp/#{couchbase_package}"
  if platform?("redhat", "centos", "suse", "fedora")
    provider Chef::Provider::Package::Rpm
    action :install
  elsif platform?("ubuntu", "debian")
    provider Chef::Provider::Package::Dpkg
    action :install
  else
    log "unsupported source package #{couchbase_package}"
    abort "unsupported source package #{couchbase_package}"
  end
end

log "configuring #{couchbase_package}"

begin
  unless (node[:block_device].nil? or
          node[:block_device][:devices].nil? or
          node[:block_device][:devices][:device1].nil? or
          node[:block_device][:devices][:device1][:mount_point].nil?)
    mount_point = node[:block_device][:devices][:device1][:mount_point]
    execute "configure data path to use mount point:  #{mount_point}" do
      command("sleep 30 && chown couchbase:couchbase #{mount_point} &&" +
              " /opt/couchbase/bin/couchbase-cli node-init" +
              "        --node-init-data-path=#{mount_point}" +
              "        -c 127.0.0.1:8091" +
              "        -u=#{node[:db_couchbase][:cluster][:username]}" +
              "        -password=#{node[:db_couchbase][:cluster][:password]}")
      action :run
    end
  end
rescue Exception => e
  log e
end

log("/opt/couchbase/bin/couchbase-cli cluster-init" +
    "        -c 127.0.0.1:8091" +
    "        --cluster-init-username=#{node[:db_couchbase][:cluster][:username]}")
execute "initializing cluster with username: #{node[:db_couchbase][:cluster][:username]}" do
  command("sleep 30" +
          " && /opt/couchbase/bin/couchbase-cli cluster-init" +
          "        -c 127.0.0.1:8091" +
          "        --cluster-init-username=#{node[:db_couchbase][:cluster][:username]}" +
          "        --cluster-init-password=#{node[:db_couchbase][:cluster][:password]}")
  action :run
end

# cluster the nodes based on cluster tag
cluster_tag = node[:db_couchbase][:cluster][:tag]
log("db_couchbase/cluster/tag: #{cluster_tag}")

known_hosts = ""
username = node[:db_couchbase][:cluster][:username]
password = node[:db_couchbase][:cluster][:password]
private_ips = ""
if cluster_tag and !cluster_tag.empty?
  now = DateTime.now.strftime("%Y%m%d-%H%M%S.%L")
  log("clustering - now is #{now}")

  unless `which rs_tag`.empty?
    ip = node[:cloud][:private_ips][0]
    if ip
      log("clustering - private ip is #{ip}")

      add_cmd = "rs_tag -a couchbase_cluster_tag:#{cluster_tag}=#{now}:#{ip}:couchbase"
      log("clustering - rs_tag add cmd: #{add_cmd}")
      add_res = `#{add_cmd}`
      log("clustering - rs_tag add res: #{add_res}")

      qry_cmd = "rs_tag -q couchbase_cluster_tag:#{cluster_tag}"
      log("clustering - rs_tag qry cmd: #{qry_cmd}")
      qry_res = `#{qry_cmd}`
      log("clustering - rs_tag qry res: #{qry_res}")

      cmd = "/opt/couchbase/bin/couchbase-cli server-list" +
        " -c 127.0.0.1" +
        " -u #{username}" +
        " -p #{password} 2>\&1"
      log("clustering - server-list cmd: #{cmd}")
      known_hosts = `#{cmd}`.strip
      log("clustering - server-list res: #{known_hosts}")
      failed_cmd = "/etc/init.d/couchbase-server stop"
      unless known_hosts.match(/^ERROR:/)
        if known_hosts.split("\n").length <= 1
          cmd = "rs_tag -q couchbase_cluster_tag:#{cluster_tag}" +
            " | grep couchbase_cluster_tag:#{cluster_tag}=" +
            " | grep -v :#{ip}:couchbase" +
            " | cut -d '=' -f 2 | cut -d '\"' -f 1 | sort | cut -d ':' -f 2"
          log("clustering - rs_tag private_ip qry: #{cmd}")
          private_ips = `#{cmd}`.strip.split("\n")
          log("clustering - rs_tag private_ip res: #{private_ips}")
          if private_ips.length >= 1

            add = "sleep 30 && /opt/couchbase/bin/couchbase-cli server-add" +
              " -c #{private_ips[0]}" +
              " -u #{username}" +
              " -p #{password}" +
              " --server-add=#{ip}" +
              " --server-add-username=#{username}" +
              " --server-add-password=#{password} 2>\&1"
              cmd = "for i in {1..5}; do x=\`#{add}\`; if [[ -z \"$x\" ]]; then break; else sleep 30 && echo 'retrying...'$i; fi; done"
              begin
                log("clustering - server-add cmd: #{cmd}")
                execute "clustering - server-add cmd: #{cmd}" do
                    command(cmd)
                    action :run
                end
                log("clustering - server added")
            rescue Exception => e
                log e
                execute "stopping couchbase server cmd: #{failed_cmd}" do
                    command(failed_cmd)
                    action :run
                end
            end

          else
            log("clustering - no other servers to join")
          end
        else
            log("clustering - already joined")
        end
      else
        log("clustering - error: could not retrieve server-list")
      end
    else
      log("clustering - error: no cloud private ip")
    end
  else
    log("clustering - error: could not find rs_tag")
  end
else
  log("clustering - skipped, no cluster_tag")
end

# rebalance if certain conditions been met
rebalance_count = node[:db_couchbase][:cluster][:rebalance_count]
num_nodes = private_ips.length + 1
if num_nodes >= rebalance_count.to_i
    reb = "/opt/couchbase/bin/couchbase-cli rebalance" +
          "  -u #{node[:db_couchbase][:cluster][:username]}" +
          "  -p #{node[:db_couchbase][:cluster][:password]}" +
          "  -c localhost:8091 2>\&1"
    cmd = "x=\`#{reb}\`; echo x"
    log("rebalancing: (num_nodes = #{num_nodes}) >= (rebalance_count = #{rebalance_count})")
    log(cmd)
    begin
      execute "rebalance cluster" do 
        command(cmd)
        action :run
      end
    rescue Exception => e
        log e
    end 
    # create bucket after rebalance
    bucket_create = "sleep 30 && /opt/couchbase/bin/couchbase-cli bucket-create" +
                "    -c 127.0.0.1:8091" +
                "    -u #{node[:db_couchbase][:cluster][:username]}" +
                "    -p #{node[:db_couchbase][:cluster][:password]}" +
                "    --bucket=#{node[:db_couchbase][:bucket][:name]}" +
                "    --bucket-type=couchbase" +
                "    --bucket-password=\"#{node[:db_couchbase][:bucket][:password]}\"" +
                "    --bucket-ramsize=#{node[:db_couchbase][:bucket][:ram]}" +
                "    --bucket-replica=#{node[:db_couchbase][:bucket][:replica]} 2>\&1"
    cmd = "x=\`#{bucket_create}\`; echo x"
    log(cmd)
    begin
      execute "creating bucket: #{node[:db_couchbase][:bucket][:name]}" do
        command(cmd)
        action :run
      end
    rescue Exception => e
        log e
    end
else
    log("rebalancing: (num_nodes = #{num_nodes}) < (rebalance_count = #{rebalance_count})")
end

rightscale_marker :end
