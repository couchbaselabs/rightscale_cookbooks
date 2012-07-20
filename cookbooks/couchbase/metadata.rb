maintainer       "Couchbase, Inc."
maintainer_email "support@couchbase.com"
license          "Copyright Couchbase, Inc. Copyright RightScale, Inc. All rights reserved."
description      "Installs/Configures Couchbase Server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.3"

depends "rightscale"

recipe "couchbase::default", "Install Couchbase Server specific packages. Setup Couchbase Server specific default attributes"

attribute "db_couchbase/cluster/username",
      :description => "Cluster REST/Web Administrator Username",
      :recipes => [ "couchbase::default" ],
      :type => "string",
      :default => "Administrator",
      :display_name => "Cluster REST/Web Username",
      :required => "optional"

attribute "db_couchbase/cluster/password",
      :description => "Cluster REST/Web Administrator Password",
      :recipes => [ "couchbase::default" ],
      :type => "string",
      :default =>  "password",
      :display_name => "Cluster REST/Web Password",
      :required => "optional"

attribute "db_couchbase/cluster/tag",
      :description => "Cluster Tag used to auto-join nodes of the same tag, when non-empty",
      :recipes => [ "couchbase::default" ],
      :type => "string",
      :default => "",
      :display_name => "Cluster Tag",
      :required => "optional"

attribute "db_couchbase/bucket/name",
      :description => "Bucket Name",
      :recipes => [ "couchbase::default" ],
      :type => "string",
      :default => "default",
      :display_name => "Bucket Name",
      :required => "optional"

attribute "db_couchbase/bucket/password",
      :description => "Bucket Password",
      :recipes => [ "couchbase::default" ],
      :type => "string",
      :default => "",
      :display_name => "Bucket Password",
      :required => "optional"

attribute "db_couchbase/bucket/ram",
      :description => "Bucket RAM Quota in MB",
      :recipes => [ "couchbase::default" ],
      :type => "string",
      :default => "2000",
      :display_name => "Bucket RAM Quota",
      :required => "optional"

attribute "db_couchbase/bucket/replica",
      :description => "Bucket Replica Count",
      :recipes => [ "couchbase::default" ],
      :type => "string",
      :default => "1",
      :display_name => "Bucket Replica Count",
      :required => "optional"

