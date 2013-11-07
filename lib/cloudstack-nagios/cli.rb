require 'erubis'

module CloudstackNagios
  class Cli < CloudstackNagios::Base
    include Thor::Actions

    package_name "cloudstack-nagios" 
    map %w(-v --version) => :version

    class_option :config,
      default: ENV['HOME'] ? File.join(Dir.home, '.cloudstack-nagios.yml') : '',
      desc: 'location of your cloudstack-nagios configuration file'

    class_option :environment,
      aliases: '-e',
      desc: 'environment to load from the configuration file'

    class_option :debug,
      desc: 'enable debug output',
      type: :boolean

    desc "version", "outputs the cloudstack-nagios version"
    def version
      say "cloudstack-nagios v#{CloudstackNagios::VERSION}"
    end

    desc "setup", "initial setup of the Cloudstack connection"
    option :url
    option :api_key
    option :secret_key
    def setup(file = options[:config])
      config = {}
      unless options[:url]
        say "Configuring #{options[:environment] || 'default'} environment."
        say "What's the URL of your Cloudstack API?", :yellow
        say "Example: https://my-cloudstack-service/client/api/"
        config[:url] = ask("URL:", :magenta)
      end
      unless options[:api_key]
        config[:api_key] = ask("API Key:", :magenta)
      end
      unless options[:secret_key]
        config[:secret_key] = ask("Secret Key:", :magenta)
      end
      if options[:environment]
        config = {options[:environment] => config}
      end
      if File.exists? file
        begin
          old_config = YAML::load(IO.read(file))
        rescue
          error "Can't load configuration from file #{config_file}."
          exit 1
        end
        say "Warning: #{file} already exists.", :red
        exit unless yes?("Do you want to merge your settings? [y/N]", :red)
        config = old_config.merge(config)
      end
      File.open(file, 'w+') {|f| f.write(config.to_yaml) }
    end

    desc "environments", "list cloudstack-nagios environments"
    def environments(file = options[:config])
      config = {}
      if File.exists? file
        begin
          config = YAML::load(IO.read(file))
        rescue
          error "Can't load configuration from file #{config_file}."
          exit 1
        end
        table = [%w(Name URL)]
        table << ["default", config[:url]]
        config.each_key do |key|
          table << [key, config[key][:url]] unless key.class == Symbol
        end
        print_table table
      end
    end
    map :envs => :environments

    # require subcommands
    Dir[File.dirname(__FILE__) + '/commands/*.rb'].each do |command| 
      require command
    end

    desc "nagios_config SUBCOMMAND ...ARGS", "Nagios configuration commands"
    subcommand :nagios_config, NagiosConfig

    desc "snmpd_config SUBCOMMAND ...ARGS", "snmpd configuration commands"
    subcommand :snmpd_config, SnmpdConfig

    desc "check SUBCOMMAND ...ARGS", "nagios checks"
    subcommand :check, Check
  end # class
end # module
