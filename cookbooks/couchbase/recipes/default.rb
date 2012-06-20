#
# Cookbook Name:: couchbase
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

rightscale_marker :begin
    
log "Downloading Couchbase Server 1.8.0"

if node[:platform] =~ /redhat|centos/
  if node["kernel"]["machine"] == "x86_64"
     remote_file "/tmp/couchbase-server.rpm" do
        source "http://packages.couchbase.com/releases/1.8.0/couchbase-server-enterprise_x86_64_1.8.0.rpm"
        mode "0644"
     end
  else
    remote_file "/tmp/couchbase-server.rpm" do
       source "http://packages.couchbase.com/releases/1.8.0/couchbase-server-enterprise_x86_1.8.0.rpm"
       mode "0644"
    end
  end
  package "couchbase-server" do
      action :install
      source "/tmp/couchbase-server.rpm"
      provider Chef::Provider::Package::Rpm
   end
end

rightscale_marker :end
