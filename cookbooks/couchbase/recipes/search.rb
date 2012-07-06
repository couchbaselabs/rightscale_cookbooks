#
# Cookbook Name:: couchbase
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

rightscale_marker :begin

node_public_ips = search(:node, "name:#{node.name.split('-').first}-*").map do |n|
  n[:cloud][:public_ips]
end

log("node_public_ips: #{node_public_ips}")

rightscale_marker :end
