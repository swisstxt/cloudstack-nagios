class NagiosConfig < CloudstackNagios::Base

  desc "hosts", "generate nagios hosts configuration for virtual routers"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_routers_hosts.cfg.erb'),
    aliases: '-t'
  def hosts
  	host_template = load_template(options[:template])
    puts host_template.result(
      routers: cs_routers,
      date: date_string
    )
  end

  desc "services", "generate nagios services configuration for virtual routers"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_routers_services.cfg.erb'),
    aliases: '-t'
  def services
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'bin'))
    config_file = options[:config]
  	service_template = load_template(options[:template])
    puts service_template.result(
      routers: cs_routers,
      bin_path: bin_path,
      config_file: config_file,
      date: date_string
    )
  end

  no_commands do
    def date_string
      Time.new.strftime("%d.%m.%Y - %H:%M:%S")
    end
  end

 end
