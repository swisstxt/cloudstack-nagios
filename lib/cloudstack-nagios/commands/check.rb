require "cloudstack-nagios/commands/system_vm"
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

   class_option :ssh_port,
      desc: 'ssh port to use',
      type: :numeric,
      default: 3922,
      aliases: '-p'

   desc "router SUBCOMMAND ...ARGS", "router checks"
   subcommand :router, Router

   desc "system_vm SUBCOMMAND ...ARGS", "system vm checks"
   subcommand :system_vm, SystemVm

   desc "capacity SUBCOMMAND ...ARGS", "capacity checks"
   subcommand :capacity, Capacity

   desc "storage_pool", "check capacity of storage pools"
   option :pool_name, required: true
   option :zone
   option :over_provisioning, type: :numeric, default: 1.0,
      desc: "Overprovisioning factor (only taken into account for type = NetworkFilesystem)"
   def storage_pool
      pool = client.list_storage_pools(name: options[:pool_name], zone: options[:zone]).first
      # calculate overprovisioning only for network file systems
      total_size = case pool['type']
      when 'NetworkFilesystem'
         pool['disksizetotal'] * options[:over_provisioning]
      else
         pool['disksizetotal']
      end
      data = check_data(
         total_size,
         pool['disksizeallocated'].to_f,
         options[:warning],
         options[:critical]
      )
      puts "storage_pool #{options[:pool_name]} #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{pool['disksizeused']} usage_perc=#{data[1]}%"
      exit data[0]
   end

   desc "async_jobs", "check the number of pending async jobs"
   option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 5,
      aliases: '-w'
   option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 10,
      aliases: '-c'
   def async_jobs
      jobs = client.send_request('command' => 'listAsyncJobs', 'listall' => 'true')['asyncjobs']
      outstanding_jobs = jobs.select {|job| job['jobstatus'] == 0 }
      if outstanding_jobs.size < options[:warning]
        code = 0
      elsif outstanding_jobs.size < options[:critical]
        code = 1
      else
        code = 2
      end
      puts "async_jobs #{RETURN_CODES[code]} - jobs = #{outstanding_jobs.size} | jobs=#{outstanding_jobs.size}"
      exit code
   end

   desc "snapshots", "check for failed snapshots (not in state 'BakedUp' for x hours)"
   option :warning,
      desc: 'warning level',
      type: :numeric,
      default: 12,
      aliases: '-w'
   option :critical,
      desc: 'critical level',
      type: :numeric,
      default: 24,
      aliases: '-c'
   def snapshots
     snapshots = []
     snapshots << client.send_request('command' => 'listSnapshots', 'projectid' => '-1')['snapshot']
     snapshots << client.send_request('command' => 'listSnapshots')['snapshot']
     snapshots.compact!.flatten!
     not_backed_up = snapshots.select{|s| s['state'] != 'BackedUp' }

     warnings = []
     critical = []

     not_backed_up.each do |s|
       age = (Time.now - Time.parse(s['created'])) / 3600
       warnings << s if age > options[:warning]
       critical << s if age > options[:critical]
     end

     code = if critical.size > 0
       2
     elsif warnings.size > 0
       1
     else
       0
     end
     puts "snapshots #{RETURN_CODES[code]} - warnings = #{warnings.size}, critical = #{critical.size} | warnings=#{warnings.size} critical=#{critical.size}"
     exit code
   end
end
