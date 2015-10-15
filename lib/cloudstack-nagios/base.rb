require "thor"
require "yaml"
require 'cloudstack_client'

module CloudstackNagios
  class Base < Thor
    include Thor::Actions
    include CloudstackNagios::Helper

    attr_reader :config

    # catch control-c and exit
    trap("SIGINT") {
      puts " bye"
      exit!
    }

    # exit with return code 1 in case of a error
    def self.exit_on_failure?
      true
    end

    no_commands do
      def client(opts = {})
        @config ||= load_configuration
        @client ||= CloudstackClient::Client.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key],
        )
        @client.debug = true if options[:debug]
        @client
      end

      def load_configuration(config_file = options[:config], env = options[:environment])
        unless File.exists?(config_file)
          say "Configuration file #{config_file} not found.", :red
          say "Please run \'cs-nagios setup\' to create one."
          exit 1
        end
        begin
          config = YAML::load(IO.read(config_file))
        rescue
          error "Can't load configuration from file #{config_file}."
          exit 1
        end
        if env
          config = config[env]
          unless config
            error "Can't find environment #{env} in configuration file."
            exit 1
          end
        end
        config
      end

      def sshoptions(ssh_key)
       {
         timeout: 5,
         keys: [ssh_key],
         auth_methods: %w(publickey)
       }
      end

    end
  end
end
