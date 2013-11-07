require 'sshkit/dsl'
require 'socket'
require 'timeout'

class SnmpdConfig < CloudstackNagios::Base

  desc "snmpd_config check [vms]", "check if snmpd is configured on virtual routers"
  def check(*vms)
    if vms.size == 0
      say 'Get a list of all routers from cloudstack..', :yellow
      vms = router_ips(routers)
    end
    vms.each do |host|
      begin
        Timeout::timeout(1) do
          socket = TCPSocket.new(host, "161")
          socket.close
          puts "port is open on host #{host}"
        end
      rescue => e
        puts "port is closed on host #{host}"
      end
    end
  end

  desc "snmpd_config enable [vms]", "enable snmpd configuration on virtual routers"
  option :apt,
      desc: 'use apt-get to install snmpd packages',
      type: :boolean
  def enable(*vms)
    apt = options[:apt]
    if vms.size == 0
      say 'Get a list of all routers from cloudstack..', :yellow
      vms = router_ips
    end
    hosts = vms.map do |router|
      host = SSHKit::Host.new("root@#{router}")
      host.ssh_options = sshoptions
      host.port = 3922
      host
    end
    say 'Connect to router and enable snmpd...', :yellow
    on hosts, in: :sequence, wait: 10 do
      begin
        execute 'apt-get', 'update'
        execute 'apt-get', '-y', 'install', 'snmpd'
        upload! File.join(File.dirname(__FILE__), '..', 'files', 'snmpd.conf'), '/etc/snmp/snmpd.conf'
        execute 'service', 'snmpd', 'restart'
        execute 'iptables', '-A INPUT -p tcp -m tcp --dport 161 -j ACCEPT'
      rescue StandardError => e 
        puts 'configuration failed!'
        puts e.message
        puts e.backtrace
      end
    end
  end

  no_commands do

    def router_ips(vrs = routers)
      ips = []
      vrs.each do |router|
        ips << router['linklocalip'] unless router['linklocalip'] == nil
      end
      ips
    end

  end

end
