require 'sshkit/dsl'

class Router < CloudstackNagios::Base

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

  desc "disk_usage", "check the disk space usage of the root volume"
  def disk_usage
    begin
      host = systemvm_host
      proc_out = ""
      on host do |h|
        proc_out = capture(:df, '/')
      end
      match = proc_out.match(/.*\s(\d+)%\s+\/$/)
      if match
        usage = match[1]
        data = check_data(100, usage, options[:warning], options[:critical])
        puts "DISK_USAGE #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{data[1]}%"
      else
        puts "DISK_USAGE UNKNOWN"
      end
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
      default: 1000000,
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
      unless options[:host]
        say "Error: --host/-H option is required for this check.", :red
        exit 1
      end
      host = SSHKit::Host.new("root@#{options[:host]}")
      host.ssh_options = sshoptions(options[:ssh_key])
      host.port = options[:ssh_port]
      host
    end

  end

end
