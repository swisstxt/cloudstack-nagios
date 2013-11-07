require 'sshkit/dsl'

class Check < CloudstackNagios::Base

  RETURN_CODES = {0 => 'ok', 1 => 'warning', 2 => 'critical'}

  desc "memory HOST", "check memory on host"
  option :host,
      desc: 'hostname or ipaddress',
      required: true,
      aliases: '-H'
  option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90,
      aliases: '-w'
  option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95,
      aliases: '-c'
  option :ssh_key,
      desc: 'ssh private key to use',
      default: '/var/lib/cloud/management/.ssh/id_rsa'
  option :port,
      desc: 'ssh port to use',
      type: :numeric,
      default: 3922,
      aliases: '-p'
  def memory
    host = SSHKit::Host.new("root@#{options[:host]}")
    host.ssh_options = sshoptions(options[:ssh_key])
    host.port = options[:port]
    free_output = ""
    on host do |h|
      free_output = capture(:free)
    end
    values = free_output.scan(/\d+/)
    total = values[0].to_i
    free = values[2].to_i
    free_b = values[7].to_i
    data = check_data(total, free_b, options[:warning], options[:critical])
    puts "MEMORY #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{data[1]}% total=#{total}M, free=#{free}M, free_wo_buffers=#{free_b}M"
    exit data[0]
  end

  desc "cpu", "check memory on host"
  option :host,
     desc: 'hostname or ipaddress',
     required: true,
     aliases: '-H'
  option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90,
      aliases: '-w'
  option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95,
      aliases: '-c'
  option :ssh_key,
      desc: 'ssh private key to use',
      default: '/var/lib/cloud/management/.ssh/id_rsa'
  option :port,
      desc: 'ssh port to use',
      type: :numeric,
      default: 3922,
      aliases: '-p'
  def cpu
    host = SSHKit::Host.new("root@#{options[:host]}")
    host.ssh_options = sshoptions(options[:ssh_key])
    host.port = options[:port]
    mpstat_output = ""
    on host do |h|
      mpstat_output = capture(:mpstat)
    end
    values = mpstat_output.scan(/\d+/)
    usage = 100 - values[-1].to_f 
    data = check_data(100, usage, options[:warning], options[:critical])
    puts "CPU #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{data[1]}%"
    exit data[0]
  end

  desc "rootfs_rw", "check if the rootfs is read/writeable on host"
  option :host,
      desc: 'hostname or ipaddress',
      required: true,
      aliases: '-H'
  option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90,
      aliases: '-w'
  option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95,
      aliases: '-c'
  option :ssh_key,
      desc: 'ssh private key to use',
      default: '/var/lib/cloud/management/.ssh/id_rsa'
  option :port,
      desc: 'ssh port to use',
      type: :numeric,
      default: 3922,
      aliases: '-p'
  def rootfs_rw
    host = SSHKit::Host.new("root@#{options[:host]}")
    host.ssh_options = sshoptions(options[:ssh_key])
    host.port = options[:port]
    proc_out = ""
    on host do |h|
      proc_out = capture(:cat, '/proc/mounts')
    end
    rootfs_rw = proc_out.match(/rootfs\srw\s/)
    status = rootfs_rw ? 0 : 2
    puts "ROOTFS_RW #{rootfs_rw ? 'OK - rootfs writeable' : 'CRITICAL - rootfs NOT writeable'}"
    exit status
  end

  desc "network", "check network usage on host"
  option :host,
      desc: 'hostname or ipaddress',
      required: true,
      aliases: '-H'
  option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90,
      aliases: '-w'
  option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95,
      aliases: '-c'
  option :ssh_key,
      desc: 'ssh private key to use',
      default: '/var/lib/cloud/management/.ssh/id_rsa'
  option :port,
      desc: 'ssh port to use',
      type: :numeric,
      default: 3922,
      aliases: '-p'
  def network
    host = SSHKit::Host.new("root@#{options[:host]}")
    host.ssh_options = sshoptions(options[:ssh_key])
    host.port = options[:port]
    r1, t1, r2, t2 = ""
    on host do |h|
      r1 = capture(:cat, '/sys/class/net/eth0/statistics/rx_bytes').to_f
      t1 = capture(:cat, '/sys/class/net/eth0/statistics/tx_bytes').to_f
      sleep 1
      r2 = capture(:cat, '/sys/class/net/eth0/statistics/rx_bytes').to_f
      t2 = capture(:cat, '/sys/class/net/eth0/statistics/tx_bytes').to_f
    end
    rbps = (r2 - r1)
    tbps = (t2 - t1)
    data = check_data(1073741824, (1073741824 - rbps), options[:warning], options[:critical])
    puts "NETWORK #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | rxbps=#{rbps.round(0)}B, txbps=#{tbps.round(0)}B"
    exit data[0]
  end

  no_commands do

    def check_data(total, usage, warning, critical)
      usage_percent = 100 - 100.0 / total.to_f * usage.to_f
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
