class Router < SystemVm

  desc "rootfs_rw", "check if the rootfs is read/writeable on host"
  def rootfs_rw
    fs_rw(mount_point: '/')
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

end
