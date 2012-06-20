#
# Cookbook Name:: lamp
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

# This is for Couchbase Server specific attribute

set_unless[:db_couchbase:bucket][:type] = "sasl"
set_unless[:db_couchbase:bucket][:name] = "default"
set_unless[:db_couchbase:bucket][:password = ""
set_unless[:db_couchbase:bucket][:ram] = "ram"
set_unless[:db_couchbase:bucket][:replica] = "1"
