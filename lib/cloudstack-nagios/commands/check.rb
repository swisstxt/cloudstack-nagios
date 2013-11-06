require 'sshkit/dsl'
require 'highline/import'
require 'socket'
require 'timeout'

class Check < CloudstackNagios::Base

  desc "memory HOST", "check memory on host"
  option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90
  option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95
  def memory(host)
    host = SSHKit::Host.new("root@#{host}")
    host.ssh_options = sshoptions
    host.port = 3922
    free_output = ""
    on host do |h|
      free_output = capture(:free)
    end
    values = free_output.scan(/\d+/)
    total = values[0].to_i
    free = values[2].to_i
    free_b = values[7].to_i
    data = check_data(total, free_b, options[:warning], options[:critical])
    puts "MEMORY #{return_codes[data[0]]} - usage = #{data[1]}% | total=#{total}, free=#{free}, free_wo_buffers=#{free_b}"
  end


  desc "memory HOST", "check memory on host"
  option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90
  option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95
  def cpu(host)
    host = SSHKit::Host.new("root@#{host}")
    host.ssh_options = sshoptions
    host.port = 3922
    mpstat_output = ""
    on host do |h|
      mpstat_output = capture(:mpstat)
    end
    values = mpstat_output.scan(/\d+/)
    usage = 100 - values[-1].to_f 
    data = check_data(100, usage, options[:warning], options[:critical])
    puts "CPU #{return_codes[data[0]]} - usage = #{data[1]}% | usage=#{usage}"
  end


  desc "network HOST", "check network usage on host"
  option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90
  option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95
  def network(host)
    host = SSHKit::Host.new("root@#{host}")
    host.ssh_options = sshoptions
    host.port = 3922
    r1, t1, r2, t2 = ""
    on host do |h|
      r1 = capture(:cat, '/sys/class/net/eth0/statistics/rx_bytes').to_f
      t1 = capture(:cat, '/sys/class/net/eth0/statistics/tx_bytes').to_f
      sleep 1
      r2 = capture(:cat, '/sys/class/net/eth0/statistics/rx_bytes').to_f
      t2 = capture(:cat, '/sys/class/net/eth0/statistics/tx_bytes').to_f
    end
    rbps = (r2 - r1) / 1024
    tbps = (t2 - t1) / 1024
    data = check_data(1048576, tbps, options[:warning], options[:critical])
    puts "NETWORK #{return_codes[data[0]]} - usage = #{data[1]}% | rxbps=#{rbps.round(0)}, txbps=#{tbps.round(0)}"
  end

  no_commands do

    def return_codes
      {0 => 'ok', 1 => 'warning', 2 => 'critical'}
    end

    def sshoptions
      {
        timeout: 5,
        keys: %w(/var/lib/cloud/management/.ssh/id_rsa),
        auth_methods: %w(publickey)
      }
    end

    def check_data(total, usage, warning, critical)
      usage_percent = 100.0 / total * usage
      code = 3
      if usage_percent < warning
        code = 0
      elsif usage_percent < critical
        code = 1
      else 
        code = 2
      end
      [code, usage_percent.round(0)]
    end

  end

end
