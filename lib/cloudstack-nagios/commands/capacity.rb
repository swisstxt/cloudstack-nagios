class Capacity < CloudstackNagios::Base

  CAPACITY_TYPES = {
    0 => {name: "Memory", method_name: "memory"},
    1 => {name: "CPU", method_name: "cpu"},
    2 => {name: "Storage", method_name: "storage"},
    3 => {name: "Primary Storage", method_name: "primary_storage"},
    4 => {name: "Public IP addresses", method_name: "public_ips"},
    5 => {name: "Private IP addresses", method_name: "private_ips"},
    6 => {name: "Secondary Storage", method_name: "secondary_storage"},
    7 => {name: "VLANs", method_name: "vlans"},
    8 => {name: "Direct Attached Public IP addresses", method_name: "direct_attached_public_ips"},
    9 => {name: "Local Storage", method_name: "local_storage"}
  }

  CAPACITY_TYPES.each do |type, value|
    desc value[:method_name], "check #{value[:name].downcase} on host"
    option :zone, required: true
    define_method(value[:method_name]) { 
      capacity_check(options[:zone], type)
    }
  end

  no_commands do
    def capacity_check(zone, type)
      cap = client.list_capacity(type: type, zone: zone).first
      data = check_data(cap['capacitytotal'].to_f, cap['capacityused'].to_f, options[:warning], options[:critical])
      puts "#{CAPACITY_TYPES[type][:name]} #{RETURN_CODES[data[0]]} - usage = #{data[1]}% | usage=#{cap['capacityused']} usage=#{data[1]}%"
      exit data[0]
    end
  end
end