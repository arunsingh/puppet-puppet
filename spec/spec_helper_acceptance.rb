require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

hosts.each do |host|
  # Install Puppet
  install_puppet

  # Install r10k for installing modules from github
  install_package host, 'rubygems'
  install_package host, 'git'
  on host, 'gem install r10k --no-ri --no-rdoc'

  puppetfile = <<-EOS
mod 'stdlib',         :git => 'git://github.com/puppetlabs/puppetlabs-stdlib.git'
mod 'concat',         :git => 'git://github.com/puppetlabs/puppetlabs-concat.git'
mod 'ruby',           :git => 'git://github.com/puppetlabs/puppetlabs-ruby.git'
mod 'puppetlabs_yum', :git => 'git://github.com/stahnma/puppet-module-puppetlabs_yum'
mod 'puppetlabs_apt', :git => 'git://github.com/puppetlabs-operations/puppet-puppetlabs_apt.git'
mod 'interval',       :git => 'git://github.com/puppetlabs-operations/puppet-interval.git'
mod 'unicorn',        :git => 'git://github.com/puppetlabs-operations/puppet-unicorn.git'
mod 'rack',           :git => 'git://github.com/puppetlabs-operations/puppet-rack.git'
mod 'bundler',        :git => 'git://github.com/puppetlabs-operations/puppet-bundler.git'
mod 'nginx',          :git => 'git://github.com/puppetlabs-operations/puppet-nginx.git'
mod 'inifile',        :git => 'git://github.com/puppetlabs/puppetlabs-inifile.git'
mod 'apache',         :git => 'git://github.com/puppetlabs/puppetlabs-apache.git'
mod 'portage',        :git => 'git://github.com/gentoo/puppet-portage.git'
  EOS
  on host, "echo \"#{puppetfile}\" > /etc/puppet/Puppetfile"
  on host, "cd /etc/puppet; r10k puppetfile install"
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    # It would be much more elegant to do this using the Modulefile and r10k or librarian-puppet
    puppet_module_install(:source => proj_root, :module_name => 'puppet')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-apt'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
