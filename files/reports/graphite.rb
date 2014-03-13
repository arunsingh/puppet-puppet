require 'puppet'
require 'yaml'
require 'socket'
require 'time'

Puppet::Reports.register_report(:graphite) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "graphite.yaml"])
  raise(Puppet::ParseError, "Graphite report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  GRAPHITE_SERVER = config[:graphite_server]
  GRAPHITE_PORT = config[:graphite_port]
  GRAPHITE_PREFIX = config[:graphite_prefix]

  desc <<-DESC
  Send notification of failed reports to a Graphite server via socket.
  DESC

  def send_metric payload
    socket = TCPSocket.new(GRAPHITE_SERVER, GRAPHITE_PORT)
    socket.puts payload
    socket.close
  end

  def process
    Puppet.debug "Sending status for #{self.host} to Graphite server at #{GRAPHITE_SERVER}"
    prefix = GRAPHITE_PREFIX + '.' + self.host.split(".").reverse.join(".")
    epochtime = Time.now.utc.to_i
    payload = self.metrics.map { |metric,data|
      data.values.map { |val|
        name = "#{prefix}.puppet.#{val[1]}_#{metric}"
        value = val[2]

        "#{name} #{value} #{epochtime}"
      }
    }

    sent_metric payload.flatten.join("\n")
  end
end
