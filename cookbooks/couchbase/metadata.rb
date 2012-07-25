maintainer       "Couchbase, Inc."
maintainer_email "support@couchbase.com"
license          "Copyright Couchbase, Inc. Copyright RightScale, Inc. All rights reserved."
description      "Installs/Configures Couchbase Server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.8"

depends "rightscale"

recipe "couchbase::default", "Install Couchbase Server specific packages. Setup Couchbase Server specific default attributes"
