#!/bin/bash
# Create Icinga Configuration upon CS router changes 
# Add this script in crontab 

date=`date +%Y%m%d%H%M`

config_path=/var/icinga/.cloudstack-nagios.yml
bin_path=/usr/local/bin/
icinga_dir=/etc/icinga/dynamic_hosts
ssh_key=/var/icinga/cloud/management/.ssh/id_rsa

#Create Icinga Cloudstack Configuration
echo "generate hostgroups"
/usr/local/bin/cs-nagios nagios_config generate hostgroups --config $config_path --ssh-key $ssh_key --bin_path $bin_path | grep -v Date > /var/icinga/core/dynamic_hosts/cloudstack_hostgroups.cfg
echo "generate router_hosts"
/usr/local/bin/cs-nagios nagios_config generate router_hosts --config $config_path --ssh-key $ssh_key --bin_path $bin_path | grep -v Date > /var/icinga/core/dynamic_hosts/cloudstack_router_hosts.cfg
echo "generate router_services"
/usr/local/bin/cs-nagios nagios_config generate router_services --config $config_path --ssh-key $ssh_key --bin_path $bin_path --if-speed 1000000000 | grep -v Date > /var/icinga/core/dynamic_hosts/cloudstack_router_services.cfg
echo "generate zone_hosts"
/usr/local/bin/cs-nagios nagios_config generate zone_hosts --config $config_path --ssh-key $ssh_key --bin-path $bin_path | grep -v Date > /var/icinga/core/dynamic_hosts/cloudstack_zone_hosts.cfg
echo "generate storage_pools"
/usr/local/bin/cs-nagios nagios_config generate storage_pools --config $config_path --ssh-key $ssh_key --bin_path $bin_path --over_provisioning 2.0 | grep -v Date > /var/icinga/core/dynamic_hosts/cloudstack_storage_pools.cfg
echo "generate capacities"
/usr/local/bin/cs-nagios nagios_config generate capacities --config $config_path --ssh-key $ssh_key --bin_path $bin_path | grep -v Date > /var/icinga/core/dynamic_hosts/cloudstack_capacity.cfg
echo "generate async_jobs"
/usr/local/bin/cs-nagios nagios_config generate async_jobs --config $config_path --ssh-key $ssh_key --bin_path $bin_path | grep -v Date > /var/icinga/core/dynamic_hosts/cloudstack_async_jobs.cfg


#Check if gengerated configuration is valid
/usr/bin/icinga -vp /var/icinga/core/icingalocaltest.cfg > /dev/null 2>&1

if [ $? -eq 0 ]
  then
  ### check if services have changed
  diff -r /var/icinga/core/dynamic_hosts /etc/icinga/dynamic_hosts > /dev/null 2>&1
  ### if config is changed copy files 
  if [ $? -eq 1 ]  
     then
     echo "Config Changed, updating now"
     cp -rp /etc/icinga/dynamic_hosts /etc/icinga/dynamic_hosts.$date
     rm -rf /etc/icinga/dynamic_hosts/*
     cp -rp /var/icinga/core/dynamic_hosts /etc/icinga/
     /usr/bin/icinga -vp /etc/icinga/icinga.cfg > /dev/null 2>&1
     if [ $? -eq 0 ]; then
        echo "Config reloaded, please reload icinga (script ready for auto reload)"
        /etc/init.d/icinga reload
     else
	echo "Problem with Global Nagios Configuration, try /usr/bin/icinga -vp /etc/icinga/icinga.cfg"
     fi
  else
      echo "Cloudstack Icinga Configuration not changed, nothing to do"
  fi
 
else
 echo "Problem with new Cloudstack Icinga Checks, try /usr/bin/icinga -vp /var/icinga/core/icingalocaltest.cfg"
fi
