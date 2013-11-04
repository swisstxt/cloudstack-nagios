class NagiosConfig < CloudstackNagios::Base

  desc "hosts", "generate nagios hosts configuration for virtual routers"
  def hosts
  	puts load_template("cloudstack_routers_hosts.cfg.erb").result(routers: routers)
  end

  desc "services", "generate nagios services configuration for virtual routers"
  def services
  	puts load_template("cloudstack_routers_services.cfg.erb").result(routers: routers)
  end

 end