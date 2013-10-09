# == Class: puppet::agent
#
# Install, configure, and run a puppet agent instance.
#
# == Parameters
#
# [*server*]
#   The puppet server to use for fetching catalogs. Required.
# [*ca_server*]
#   The puppet server to use for certificate requests and similar actions.
#   Default: puppet::agent::server
# [*report_server*]
#   The puppet server to send reports.
#   Default: puppet::agent::server
# [*manage_repos*]
#   Whether to manage Puppet Labs APT or YUM package repos.
#   Default: true
# [*method*]
#   The mechanism for performing puppet runs.
#   Supported methods: [cron, service]
#   Default: cron
# [*monitor_service*]
#   Whether or not to monitor the puppet service.
#   Should not be mixed when method is cron.
#   Default: false
# [*environment*]
#   What environment the agent should be part of.
#   Default: production
#
# == Example:
#
#   class { 'puppet::agent':
#     server        => 'puppet.example.com',
#     report_server => 'puppet_reports.example.com',
#     method        => 'service',
#  }
#
class puppet::agent(
  $server          = 'puppet',
  $ca_server       = 'puppet',
  $report_server   = 'puppet',
  $report_format   = undef,
  $manage_repos    = true,
  $method          = 'cron',
  $ensure          = 'present',
  $monitor_service = false,
  $environment     = 'production',
) {

  include puppet

  if $manage_repos {
    include puppet::package
  }

  class { '::puppet::agent::monitor': enable => $monitor_service }

  case $method {
    cron:    { include puppet::agent::cron }
    service: { include puppet::agent::service }
    none:    { }
    default: {
      notify { "Agent run method \"${method}\" is not supported by ${module_name}, defaulting to cron": loglevel => warning }
      include puppet::agent::cron
    }
  }

  # ----
  # puppet.conf management
  concat::fragment { 'puppet.conf-agent':
    order   => '03',
    target  => $puppet::params::puppet_conf,
    content => template("puppet/puppet.conf/agent.erb");
  }
}
