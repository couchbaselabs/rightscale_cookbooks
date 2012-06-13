maintainer       "Couchbase, Inc."
maintainer_email "support@couchbase.com"
license          "Copyright RightScale, Inc. All rights reserved."
description      "Installs/Configures Couchbase Server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1"

depends "db_mysql"
depends "app_php"

recipe "lamp::default", "Install Couchbase Server specific packages. Setup Couchbase Server specific default attributes"
