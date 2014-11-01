class puppet::server::thin {

  include puppet::params
  include puppet::server::rack

  notify { 'Thin Support Pending Removal':
    message  => 'Thin support  on the Puppet Master may be removed from the
    puppet-puppet module!  Please see
    https://github.com/puppetlabs-operations/puppet-puppet/issues/110 for more
    detail.  Support will be removed if no users of the feature speak up.',
    loglevel => 'warning',
  }

  class { 'puppet::server::standalone': enabled => false }
  class { '::thin': }
  class { 'nginx::server': }

  Ini_setting {
    ensure  => 'present',
    section => 'master',
    path    => $puppet::params::puppet_conf,
  }

  ini_setting {
    'ssl_client_header':
      ensure  => 'absent',
      setting => 'ssl_client_header';
    'ssl_client_verify_header':
      ensure  => 'absent',
      setting => 'ssl_client_verify_header';
  }

  $servers = $::processorcount
  nginx::vhost { 'puppetmaster':
    port     => 8140,
    template => 'puppet/vhost/nginx/thin.conf.erb',
  }

  concat::fragment { 'proctitle':
    order  => '05',
    target => "${::puppet::params::puppet_confdir}/config.ru",
    source => 'puppet:///modules/puppet/config.ru/05-proctitle.rb',
  }

  thin::app { 'puppetmaster':
    user       => 'puppet',
    group      => 'puppet',
    rackup     => "${::puppet::params::puppet_confdir}/config.ru",
    chdir      => $puppet::params::puppet_confdir,
    subscribe  => Concat["${::puppet::params::puppet_confdir}/config.ru"],
    require    => Class['::thin'],
    socket     => '/var/run/thin/puppetmaster.sock',
    force_home => '/etc/puppet',
  }
}
