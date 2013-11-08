require 'sshkit/dsl'

class Check < CloudstackNagios::Base

  RETURN_CODES = {0 => 'ok', 1 => 'warning', 2 => 'critical'}

  class_option :host,
      desc: 'hostname or ipaddress',
      required: true,
      aliases: '-H'

  class_option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90,
      aliases: '-w'

  class_option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95,
      aliases: '-c'

  class_option :ssh_key,
      desc: 'ssh private key to use',
      default: '/var/lib/cloud/management/.ssh/id_rsa'

  class_option :port,
      desc: 'ssh port to use',
      type: :numeric,
      default: 3922,
      aliases: '-p'

  desc "memory HOST", "check memory on host"
  def memory
    begin
      host = systemvm_host
      free_output = ""
      on host do |h|
        free_output = capture(:free)
      end
      values = free_output.scan(/\d+/)
      total = values[0].to_i
      free = values[2].to_i
      free_b = values[7].to_i
      data = check_data(total, total - free_b, options[:warning], options[:critical])
      puts "MEMORY #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{data[1]}% total=#{total}M free=#{free}M free_wo_buffers=#{free_b}M"
      exit data[0]
    rescue => e
      exit_with_failure(e)
    end
  end

  desc "cpu", "check memory on host"
  def cpu
    begin
      host = systemvm_host
      mpstat_output = ""
      on host do |h|
        mpstat_output = capture(:mpstat)
      end
      values = mpstat_output.scan(/\d+\.\d+/)
      usage = 100 - values[-1].to_f 
      data = check_data(100, usage, options[:warning], options[:critical])
      puts "CPU #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{data[1]}%"
      exit data[0]
    rescue => e
      exit_with_failure(e)
    end
  end

  desc "rootfs_rw", "check if the rootfs is read/writeable on host"
  def rootfs_rw
    begin
      host = systemvm_host
      proc_out = ""
      on host do |h|
        proc_out = capture(:cat, '/proc/mounts')
      end
      rootfs_rw = proc_out.match(/rootfs\srw\s/)
      status = rootfs_rw ? 0 : 2
      puts "ROOTFS_RW #{rootfs_rw ? 'OK - rootfs writeable' : 'CRITICAL - rootfs NOT writeable'}"
      exit status
    rescue => e
      exit_with_failure(e)
    end
  end

  desc "network", "check network usage on host"
  option :interface,
      desc: 'network interface to probe',
      default: 'eth0',
      aliases: '-i'
  option :if_speed,
      desc: 'network interface speed in bits per second',
      type: :numeric,
      default: 1000000000,
      aliases: '-s'
  def network
    begin
      host = systemvm_host
      stats_path = "/sys/class/net/#{options[:interface]}/statistics"
      rx_bytes, tx_bytes = ""
      on host do |h|
        rx_bytes = capture("cat #{stats_path}/rx_bytes;sleep 1;cat #{stats_path}/rx_bytes").lines.to_a
        tx_bytes = capture("cat #{stats_path}/tx_bytes;sleep 1;cat #{stats_path}/tx_bytes").lines.to_a
      end
      rbps = (rx_bytes[1].to_i - rx_bytes[0].to_i) * 8
      tbps = (tx_bytes[1].to_i - tx_bytes[0].to_i) * 8
      data = check_data(options[:if_speed], rbps, options[:warning], options[:critical])
      puts "NETWORK #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{data[1]}% rxbps=#{rbps.round(0)} txbps=#{tbps.round(0)}"
      exit data[0]
    rescue => e
      exit_with_failure(e)
    end
  end

  no_commands do

    def systemvm_host
      host = SSHKit::Host.new("root@#{options[:host]}")
      host.ssh_options = sshoptions(options[:ssh_key])
      host.port = options[:port]
      host
    end

    def exit_with_failure(exception)
      say 'ERROR: command execution failed!', :red
      say "Message: ", :magenta
      say exception.message
      say "Backtrace:", :magenta
      say exception.backtrace
      exit 3
    end

    def check_data(total, usage, warning, critical)
      usage_percent = 100.0 / total.to_f * usage.to_f
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
