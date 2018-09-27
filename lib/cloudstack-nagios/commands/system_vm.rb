require 'sshkit'

class SystemVm < CloudstackNagios::Base
  include SSHKit::DSL

  desc "memory HOST", "check memory on host"
  def memory
    begin
      host = systemvm_host
      free_output = ""
      on host do |h|
        free_output = capture(:cat, '/proc/meminfo')
      end
      values = free_output.scan(/\d+/)
      total = values[0].to_i
      free = values[1].to_i
      free_b = values[1].to_i + values[3].to_i + values[4].to_i
      data = check_data(total, total - free_b, options[:warning], options[:critical])
      puts "MEMORY #{RETURN_CODES[data[0]]} - usage = #{data[1]}% (#{((total - free_b)/1024.0).round(0)}/#{(total/1024.0).round(0)}MB) | \
            usage=#{data[1]}% total=#{total}M free=#{free}M free_wo_buffers=#{free_b}M".gsub(/\s+/, " ")
      exit data[0]
    rescue => e
      exit_with_failure(e)
    end
  end

  desc "cpu", "check memory on host"
  option :mode,
    desc: "average mode gives the average value over all CPU's and max the highest usage of any CPU",
    :enum => %w(average max),
    aliases: '-m',
    default: 'average'
  def cpu
    begin
      host = systemvm_host
      mpstat_output = ""
      on host do |h|
        mpstat_output = capture(:mpstat, '-P ALL', '2', '2')
      end
      # max takes the min idle value, removes zero values before
      value = if options[:mode] == "max"
        values = mpstat_output.each_line.to_a.slice(3..-1).map do |line, index|
          line.scan(/\d+\.\d+/)[-1].to_f
        end
        values.delete(0.0)
        values.min
      else
        mpstat_output.scan(/\d+\.\d+/)[-1].to_f
      end
      usage = 100 - value
      data = check_data(100, usage, options[:warning], options[:critical])
      puts "CPU #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{data[1]}%"
      exit data[0]
    rescue => e
      exit_with_failure(e)
    end
  end

  desc "fs_rw", "check if a certain mount point is read/writeable on host"
  option :mount_point, desc: "The mount point to check", default: '/', aliases: '-m'
  def fs_rw
    begin
      host = systemvm_host
      test_file = File.join(options[:mount_point], 'cs_nagios_diskcheck.txt')
      fs_rw = false
      on host do |h|
        fs_rw = execute(:touch, test_file)
        execute(:rm, '-f', test_file)
      end
    rescue SSHKit::Command::Failed
      fs_rw = false
    rescue => e
      exit_with_failure(e)
    end
    status = fs_rw ? 0 : 2
    puts fs_rw ?
      "OK - file system (#{options[:mount_point]}) writeable" :
      "CRITICAL - file system (#{options[:mount_point]}) NOT writeable"
    exit status
  end

  desc "secstor_rw", "check if all secstorage mounts are read/writeable on host"
  def secstor_rw
    host = systemvm_host
    mounts = {}
    on host do |h|
      entries = capture(:mount, '|grep SecStorage') rescue ''
      entries.each_line do |nfs_mount|
        mount_point = nfs_mount[/.* on (.*) type .*/, 1]
        test_file = File.join(mount_point, 'cs_nagios_diskcheck.txt')
        fs_rw = execute(:touch, test_file) rescue false
        mounts[mount_point] = fs_rw
        execute(:rm, '-f', test_file) if fs_rw
      end
    end
    fs_ro = mounts.select {|key,value| value != true}
    status = fs_ro.size == 0 ? 0 : 2
    puts status == 0 ?
      "OK - all sec_stor mounts are writeable" :
      "CRITICAL - some sec_stor mounts are NOT writeable (#{fs_ro.keys.join(', ')})"
    exit status
  rescue => e
    exit_with_failure(e)
  end

  desc "disk_usage", "check the disk space usage of the root volume"
  option :partition, desc: "The partition to check", default: '/', aliases: '-P'
  def disk_usage
    begin
      host = systemvm_host
      partition = options[:partition]
      proc_out = ""
      on host do |h|
        proc_out = capture(:df, '-l', partition)
      end
      match = proc_out.match(/.*\s(\d+)%\s.*/)
      if match
        usage = match[1]
        data = check_data(100, usage, options[:warning], options[:critical])
        puts "DISK_USAGE #{RETURN_CODES[data[0]]} (Partition #{options[:partition]}) - usage = #{data[1]}% | usage=#{data[1]}%"
        exit data[0]
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

  desc "conntrack_connections", "check the number of conntrack connections"
  def conntrack_connections
    begin
      host = systemvm_host
      default_max = 1000000
      netfilter_path = "/proc/sys/net/netfilter/"
      current, max = 0
      on host do |h|
        max     = capture("cat #{netfilter_path}nf_conntrack_max").to_i
        current = capture("cat #{netfilter_path}nf_conntrack_count").to_i
      end
      if max < default_max
        on host do |h|
          execute :echo, "#{default_max} > #{netfilter_path}nf_conntrack_max"
        end
      end
      data = check_data(max, current, options[:warning], options[:critical])
      puts "CONNTRACK_CONNECTIONS #{RETURN_CODES[data[0]]} - usage = #{data[1]}% (#{current.round(0)}/#{max.round(0)}) | usage=#{data[1]}% current=#{current.round(0)} max=#{max.round(0)}"
      exit data[0]
    rescue => e
      exit_with_failure(e)
    end
  end

  desc "active_ftp", "make sure conntrack_ftp and nf_nat_ftp modules are loaded"
  def active_ftp
    begin
      host = systemvm_host
      active_ftp_enabled = false
      modules = %w(nf_conntrack_ftp, nf_nat_ftp)
      on host do |h|
        lsmod = capture(:lsmod)
        active_ftp_enabled = lsmod.include?('nf_conntrack_ftp') &&
          lsmod.include?('nf_nat_ftp')
        unless active_ftp_enabled
          # load the modules in the kernel
          execute(:modprobe, 'nf_conntrack_ftp')
          execute(:modprobe, 'nf_nat_ftp')
          # load the modules at next server boot
          execute(:echo, '"nf_conntrack_ftp" >> /etc/modules')
          execute(:echo, '"nf_nat_ftp" >> /etc/modules')
          active_ftp_enabled = true
        end
      end
    rescue SSHKit::Command::Failed
      active_ftp_enabled = false
    rescue => e
      exit_with_failure(e)
    end
    status = active_ftp_enabled ? 0 : 2
    puts "ACTIVE_FTP #{active_ftp_enabled ? 'OK - active_ftp enabled' : 'CRITICAL - active_ftp NOT enabled'}"
    exit status
  end

  no_commands do

    def systemvm_host
      unless options[:host]
        say "Error: --host/-H option is required for this check.", :red
        exit 1
      end
      # suppress sshkit output to stdout
      SSHKit.config.output_verbosity = Logger::FATAL
      host = SSHKit::Host.new("root@#{options[:host]}")
      host.ssh_options = sshoptions(options[:ssh_key])
      host.port = options[:ssh_port]
      host
    end

  end

end
