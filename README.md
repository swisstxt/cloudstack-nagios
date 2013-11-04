# Cloudstack Nagios

Cloudstack Nagios helps you monitoring your Cloudstack environment with Nagios.
Cloudstack Nagios uses the Cloudsdtack API to collect information about system vm's and cloudstack ressources.

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

See the help screen:

    $ cs-nagios

Generate nagios host and services configuration for virtual routers:

    $ cs-nagios config

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
