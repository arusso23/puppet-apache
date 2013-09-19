# == Define: apache::vhost
#
# Defines an apache vhost
#
# === Parameters:
#
# [*document_root*]
#   VirtualHosts document root.  We do not attempt to manage this directory
#   in any way -- we just tell apache to look there.
#
#  Usage:
#    document_root = '/path/to/doc/root'
#
# [*is_default*]
#   Distinguishes the vhost as the default one, naming the configuration file
#   appropriately such that it will come before non-default vhosts. Multiple
#   vhosts with is_default set will resort to sorting by $server_name.
#
#  Usage:
#    is_default = true
#  or
#    is_default = false
#
# [*server_alias*]
#   Comma seperated or array value of the hostnames that this this virtual host
#   respond to.
#
#  Usage:
#    server_alias = [ 'host1.example.com', 'host2.example.com' ]
#  or
#    server_alias = 'host1.example.com,host2.example.com'
#
# [*server_name*]
#   String indicating the primary hostname for this vhost.
#
#  Usage:
#    server_name = 'host.example.com'
#
# [*ssl*]
#   Boolean indicating whether we should enable SSL for this vhost
#
#  Usage:
#    ssl = true
#  or
#    ssl = 'true'
#
# [*ssl_key_file*]
#   String location of the SSL key file
#
#  Usage:
#    ssl_key_file = '/etc/pki/tls/private/host.example.com.key'
#
# [*ssl_crt_file*]
#   String location of the SSL certificate file
#
#  Usage:
#    ssl_crt_file = '/etc/pki/tls/certs/host.example.com.crt'
#
# [*ssl_int_file*]
#   String location of the SSL intermediate certificate chain.  If this is not
#   set, the SSLCertificateChainFile directive is not set.  Use this when you
#   have a self-signed cert, or you haven't installed the intermediate cert from
#   your signing CA.
#
#  Usage:
#    ssl_int_file = '/etc/pki/tls/certs/intermediate.crt'
#
# === Example:
#
# apache::vhost { 'www.example.com':
#    server_alias => [ 'example.com' ],
# }
#
# apache::vhost { 'app.example.com':
#   server_alias  => [ 'app-prod.example.com' ],
#   ssl          => true,
#   ssl_key_file => '/etc/pki/tls/private/app-prod.example.com.key',
#   ssl_crt_file => '/etc/pki/tls/certs/app-prod.example.com.crt',
#   ssl_int_file => '/etc/pki/tls/certs/intermediate.crt,
# }
define apache::vhost (
  $is_default = false,
  $document_root = params_lookup( 'document_root', false ),
  $server_alias = params_lookup( 'server_alias', false, '' ),
  $server_name = params_lookup( 'server_name', false, $name),
  $ssl = params_lookup( 'ssl', false ),
  $ssl_key_file = params_lookup( 'ssl_key_file', false ),
  $ssl_crt_file = params_lookup( 'ssl_crt_file', false ),
  $ssl_int_file = params_lookup( 'ssl_int_file', false )
) {
  include apache::namevirtualhost

  if $document_root { validate_absolute_path( $document_root ) }

  # Let's add our server_name to the server_alias array
  $server_alias_real = is_array( $server_alias) ? {
      true => unique(flatten([ $server_name, $server_alias])),
      default => unique(flatten([ $server_name, split( $server_alias, ',' )])),
  }
  validate_array( $server_alias_real )

  # Check our SSL parameters if we've enabled ssl
  $ssl_real = type( $ssl ) ? {
    string => any2bool( $ssl ),
    boolean => $ssl,
  }
  validate_bool( $ssl_real )

  $ord = $is_default ? { true => '0', default => '1' }
  if $ssl_real {
    # include our class to setup the ssl module for apache
    include apache::mod::ssl

    # establish the relationship between our SSL cert and our
    # config file, ensuring it exists before we try to use it
    Ssl::Cert[$name]->
      File["${apache::params::vhost_dir}/vhost-${ord}-${server_name}.conf"]

    validate_absolute_path( $ssl_key_file )
    validate_absolute_path( $ssl_crt_file )
    # if we haven't downloaded the signed cert (or its self signed), we want to
    # be able to disable the intermediate file.  So if it's empty, lets not
    # worry about if thats the case
    if ! $ssl_int_file == undef { validate_absolute_path( $ssl_int_file ) }

    # Our user-editable config file
    file { "${apache::params::vhost_dir}/vhost-${server_name}.ssl.include":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/apache/vhost.include',
      replace => false,
    } # vhost.ssl.include
  } # if ssl_real

  # Our primary config file, not user editable
  file { "${apache::params::vhost_dir}/vhost-${ord}-${server_name}.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('apache/vhost.conf.erb'),
  }

  # Our user-editable config file
  file { "${apache::params::vhost_dir}/vhost-${server_name}.include":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/apache/vhost.include',
    replace => false,
  }
}
