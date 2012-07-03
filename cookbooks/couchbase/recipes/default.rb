#
# Cookbook Name:: couchbase
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

rightscale_marker :begin

couchbase_version = "1.8.1"

log "Downloading Couchbase Server #{couchbase_version}"

if node[:platform] =~ /redhat|centos/ and not File.exists?("/tmp/couchbase-server.rpm")
  remote_file "/tmp/couchbase-server.rpm" do
    mach = "x86"
    mach = "x86_64" if node["kernel"]["machine"] == "x86_64"
    source "http://packages.couchbase.com/releases/#{couchbase_version}/couchbase-server-enterprise_x86_64_#{couchbase_version}.rpm"
    mode "0644"
  end

  package "couchbase-server" do
    action :install
    source "/tmp/couchbase-server.rpm"
    provider Chef::Provider::Package::Rpm
  end
end

execute "initialize couchbase cluster with username:#{node[:db_couchbase][:cluster][:username]}" do
  command("sleep 10" +
          " && /opt/couchbase/bin/couchbase-cli cluster-init" +
          "        -c 127.0.0.1:8091" +
          "        --cluster-init-username=#{node[:db_couchbase][:cluster][:username]}" +
          "        --cluster-init-password=#{node[:db_couchbase][:cluster][:password]}")
  action :run
end

execute "create bucket" do
  command("/opt/couchbase/bin/couchbase-cli bucket-create" +
          "    -c 127.0.0.1:8091" +
          "    -u #{node[:db_couchbase][:cluster][:username]}" +
          "    -p #{node[:db_couchbase][:cluster][:password]}" +
          "    --bucket=#{node[:db_couchbase][:bucket][:name]}" +
          "    --bucket-type=couchbase" +
          "    --bucket-password=\"#{node[:db_couchbase][:bucket][:password]}\"" +
          "    --bucket-ramsize=#{node[:db_couchbase][:bucket][:ram]}" +
          "    --bucket-replica=#{node[:db_couchbase][:bucket][:replica]}")
  action :run
end

rightscale_marker :end
