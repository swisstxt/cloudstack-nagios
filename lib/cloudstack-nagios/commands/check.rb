require "cloudstack-nagios/commands/router"
require "cloudstack-nagios/commands/capacity"

class Check < CloudstackNagios::Base
   default_task :help

   class_option :host,
      desc: 'hostname or ipaddress',
      aliases: '-H'

   class_option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 90,
      aliases: '-w'

   class_option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 95,
      aliases: '-c'

   class_option :ssh_key,
      desc: 'ssh private key to use',
      default: '/var/lib/cloud/management/.ssh/id_rsa'

   class_option :port,
      desc: 'ssh port to use',
      type: :numeric,
      default: 3922,
      aliases: '-p'

   desc "router SUBCOMMAND ...ARGS", "router checks"
   subcommand :router, Router

   desc "capacity SUBCOMMAND ...ARGS", "capacity checks"
   subcommand :capacity, Capacity

   desc "storage_pool SUBCOMMAND ...ARGS", "storage_pool checks"
   subcommand :capacity, Capacity

   desc "capacity", "check capacity of storage_pool"
   option :pool_name, required: true
   option :zone
   option :over_provisioning, type: :numeric, default: 1.0
   def storage_pool
      pool = client.list_storage_pools(name: options[:pool_name], zone: options[:zone]).first
      data = check_data(
         pool['disksizetotal'] * options[:over_provisioning],
         pool['disksizeallocated'].to_f,
         options[:warning],
         options[:critical]
      )
      puts "storage_pool #{options[:pool_name]} #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{pool['disksizeused']}"
      exit data[0]
   end

end