require 'sshkit/dsl'
require 'highline/import'

class SnmpdConfig < CloudstackNagios::Base

  desc "check", "check if snpd is configured on virtual routers"
  def check
  	
  end

  desc "enable", "enable snmpd configuration on virtual routers"
  def enable
  	hosts = routers.map {|router| router['linklocalip']}
  	on hosts, in: :sequence, wait: 5 do
			puts
			puts "On host #{host}"
			puts "____" * 20
			puts
  		puts output = capture(:free, '-m')
  		puts output =~ /Mem:\s+(\d+)\s+(\d+)/
  		puts $1
  		puts $2
		end
  end

  no_commands do

  	def snmp_hosts(host_names)
  		hosts = host_names.map do |host_name|
				host = SSHKit::Host.new("root@#{host_name}")
				host
			end
		end

	end

end