class NagiosConfig < CloudstackNagios::Base

  TEMPLATE_DIR = File.join(File.dirname(__FILE__), '..', 'templates')

  desc "generate [type]", "generate all nagios configs"
  option :bin_path, desc: "absolute path to the nagios-cloudstack binary"
  option :template,
    desc: "Path of ERB template to use. Only valid when generating a single configuration",
    aliases: '-t'
  option :if_speed,
    desc: 'network interface speed in bits per second',
    type: :numeric,
    default: 1000000,
    aliases: '-s'
  option :ssh_key,
      desc: 'ssh private key to use',
      default: '/var/lib/cloud/management/.ssh/id_rsa'
  option :ssh_port,
    desc: 'ssh port to use',
    type: :numeric,
    default: 3922,
    aliases: '-p'
  option :over_provisioning, type: :numeric, default: 1.0
  def generate(*configs)
    configs = get_configs(configs)
    if configs.size == 0
      say "Please specify a valid configuration.", :green
      say "Possible values are..."
      invoke "nagios_config:list", []
      exit
    end

    routers = configs.include?("router_hosts") ? cs_routers : nil
    pools = configs.include?("storage_pools") ? storage_pools : nil
    zones = client.list_zones
    config_name = configs.size == 1 ?
      "#{configs[0]} configuration" :
      "all configurations"

    header = load_template(File.join(TEMPLATE_DIR, "header.cfg.erb"))
    output = header.result(
      config_name: config_name,
      date: date_string
    )
    configs.each do |config|
      if configs.size == 1 && options[:template]
        tmpl_file = options[:template]
      else
        tmpl_file = File.join(TEMPLATE_DIR, "cloudstack_#{config}.cfg.erb")
      end
      template = load_template(tmpl_file)
      output += template.result(
        routers: routers,
        bin_path: bin_path,
        if_speed: options[:if_speed],
        config_file: options[:config],
        zones: zones,
        capacity_types: Capacity::CAPACITY_TYPES,
        storage_pools: pools,
        over_provisioning: options[:over_provisioning],
        ssh_key: options[:ssh_key],
        ssh_port: options[:ssh_port]
      )
    end
    footer = load_template(File.join(TEMPLATE_DIR, "footer.cfg.erb"))
    output += footer.result(
      config_name: config_name
    )
    puts output
  end

  desc "list", "show a list of possible configurations which can be generated."
  def list
    configs = get_configs
    puts ["all"] << configs
  end

  no_commands do

    def get_configs(configs = [])
      all_configs = %w(hostgroups zone_hosts router_hosts router_services capacities async_jobs storage_pools)
      if configs.size == 0
        return all_configs
      else
        if configs.size == 1 && configs[0].downcase == "all"
          return all_configs
        end
        return all_configs.select { |config| configs.include? config }
      end
    end

    def date_string
      Time.new.strftime("%d.%m.%Y - %H:%M:%S")
    end

    def bin_path
      unless options[:bin_path]
        return ''
      else
        return options[:bin_path].end_with?('/') ? options[:bin_path] : options[:bin_path] + "/"
      end
    end
  end

 end