class NagiosConfig < CloudstackNagios::Base

  desc "hosts", "generate nagios hosts configuration for virtual routers"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_routers_hosts.cfg.erb'),
    aliases: '-t'
  def hosts
  	host_template = load_template(options[:template])
    puts host_template.result(routers: cs_routers)
  end

  desc "services", "generate nagios services configuration for virtual routers"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_routers_services.cfg.erb'),
    aliases: '-t'
  def services
  	service_template = load_template(options[:template])
    puts service_template.result(routers: cs_routers)
  end

 end
