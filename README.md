# Cloudstack Nagios

Cloudstack Nagios helps you monitoring your Cloudstack environment with Nagios.
Cloudstack Nagios uses the Cloudsdtack API to collect information about system vm's and cloudstack ressources.

## Prerequisites

  * Cloudstack Root Admin keys must be used.
  * In order to connect to system vms the private ssh key found on the Cloudstack management server under /var/lib/cloud/management/.ssh/id_rsa must be used.
  * The system vms must be reachable over SSH (default port 3922) from the nagios server executing the checks.
    * check with 'ssh -i /var/lib/cloud/management/.ssh/id_rsa -p 3922 <router_mgmt_ip>'

## Installation

Install the cloudstack-cli gem:

    $ gem install cloudstack-nagios

## Setup

Create the initial configuration:

    $ cs setup

cloudstack-nagios expects to find a configuartion file with the API URL and your CloudStack credentials in your home directory named .cloudstack-cli.yml. If the file is located elsewhere you can specify the loaction using the --config option.

cloudstack-nagios supports multiple environments using the --environment option.

Example content of the configuration file:

    :url:         "https://my-cloudstack-server/client/api/"
    :api_key:     "cloudstack-api-key"
    :secret_key:  "cloudstack-api-secret"

    test:
      :url:         "http://my-cloudstack-testserver/client/api/"
      :api_key:     "cloudstack-api-key"
      :secret_key:  "cloudstack-api-secret"

## Usage

### Basics

See the help screen:

    $ cs-nagios

### Generate Nagios configuration files

Generate nagios host configuration for virtual routers:

    $ cs-nagios nagios_config host

Generate nagios host configuration for virtual routers:

    $ cs-nagios nagios_config service

Note that you can also use your own ERB templates using the '--template' option to generate the nagios confifuration files.

### Check system vms over ssh

The following checks are available:
  
   * memory - measure memory usage in percents
   * cpu - measure cpu usage in percent
   * network - measure network usage
   * rootfs_rw - check if the root file system is writeable

### Enabling snmpd checks

If you want to check your system vms with standard snmp checks instead of checking over SSH, there are commands to configure snmpd on the machines and open the firewall.

   * snmpd_config enable - goes to all the routers and configure snmpd
   * snmpd_config check - test if port TCP 161 is reachable on routers

Note: If you want to use snmp checks, you have to adapt the nagios configuration files accordingly.

## References
-  [Cloudstack API documentation](http://cloudstack.apache.org/docs/api/apidocs-4.2/TOC_Root_Admin.html)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT License. See the [LICENSE](https://bitbucket.org/swisstxt/cloudstack-cli/raw/master/LICENSE.txt) file for further details.
