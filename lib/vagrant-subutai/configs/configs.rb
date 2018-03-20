module VagrantSubutai
  module Configs
    module VagrantCommand
      INIT        = 'vagrant init'.freeze
      UP          = 'vagrant up'.freeze
      RH_UP       = 'SUBUTAI_PEER=false vagrant up'.freeze
      PROVISION   = 'vagrant provision'.freeze
      SUBUTAI_ID  = 'vagrant subutai --info id'.freeze
      ARG_IP_ADDR = 'ipaddr'.freeze
    end

    module Ansible
      TEMPLATE_NAME = 'generic-ansible'.freeze
    end

    module Quota
      # CPU       percentage %
      # RAM, DISK unit Gigabytes
      RESOURCE = {
                   TINY:    { CPU: 10,  RAM: 0.25, DISK: 4 },
                   SMALL:   { CPU: 25,  RAM: 0.5,  DISK: 10 },
                   MEDIUM:  { CPU: 50,  RAM: 1,    DISK: 20 },
                   LARGE:   { CPU: 75,  RAM: 2,    DISK: 40 },
                   HUGE:    { CPU: 100, RAM: 4,    DISK: 100 }
                  }.freeze
    end

    module Blueprint
      SCHEME = {
                 name:            'name',
                 description:     'My static website',
                 version:         'Blueprint version',
                 'author':        'Author',
                 'ssh-key':        'ssh-key-name',
                 containers:      [
                                   {
                                     hostname:   'www',
                                     template:   'apache',
                                     size:       'TINY',
                                     'peer-criteria':   'HTTP-GROUP',
                                     'port-mapping':     [
                                                          {
                                                            protocol:      'http',
                                                            domain:        '${domain}',
                                                            'internal-port':  '80',
                                                            'external-port':  '80'
                                                          },
                                                          {
                                                            protocol:       'tcp',
                                                            domain:         '${domain}',
                                                            'internal-port':  '22',
                                                            'external-port':  '4040'
                                                          }
                                                         ]
                                   }
                                  ],
                 'peer-criteria':   [
                                     {
                                       name:                   'HTTP-GROUP',
                                       'max-price':            '5',
                                       'avg-cpu-load':         '50',
                                       'min-free-ram':         '128',
                                       'min-free-disk-space':  '10'
                                     }
                                    ],
                 'ansible-configuration': {
                     'source-url': 'zip_file_url',
                     'ansible-playbook': 'any_name',
                     'extra-vars': [
                         {
                             'key': 'any_name',
                             'value': 'any_name_value'
                         }
                     ],
                     'groups': [
                         {
                             'name': 'any_name',
                             'python-interpreter': '/usr/bin/python3',
                             'hostnames': [
                                 'hostname_of_container'
                             ]
                         }
                     ]
                 },
                 'user-variables':  {
                                       any_name: {
                                                 description: 'Select your domain or create new one',
                                                 type:        'domain',
                                                 default:     'site.env.subutai.cloud',
                                                 validation:  '[a-zA-Z0-9.-]+'
                                               }
                                     }
               }.freeze
      CONTAINER_SIZES = %w(TINY SMALL MEDIUM LARGE HUGE).freeze

      module MODE
        PEER   = 'peer'.freeze
        BAZAAR = 'bazaar'.freeze
      end
    end

    module Environment
      PROD   = 'prod'.freeze
      DEV    = 'dev'.freeze
      SYSNET = 'sysnet'.freeze
      MASTER = 'master'.freeze
    end

    module SubutaiConsoleAPI
      PORT    = '8443'.freeze
      COMMAND = '/rest/ui/commands?sptoken='.freeze
      COMMAND_ASYNC = '/rest/ui/commands/async?sptoken='.freeze
      COMMAND_LOG   = '/rest/ui/commands/async/{COMMAND_ID}?sptoken='.freeze

      module V1
        TOKEN        = '/rest/v1/identity/gettoken'.freeze
        REGISTER_HUB = '/rest/v1/hub/register?sptoken='.freeze
        APPROVE      = '/rest/v1/registration/requests'.freeze
        FINGERPRINT  = '/rest/v1/security/keyman/getpublickeyfingerprint'.freeze
        REQUESTS     = '/rest/v1/registration/requests?sptoken='.freeze
        ENVIRONMENT  = '/rest/v1/environments?sptoken='.freeze
        HOSTS        = '/rest/v1/hosts?sptoken='.freeze
        ENVIRONMENTS = '/rest/v1/environments?sptoken='.freeze
        LOG          = '/rest/v1/tracker/operations/ENVIRONMENT%20MANAGER/'.freeze
        RESOURCES    = '/rest/v1/peer/resources?sptoken='.freeze
        DOMAIN       = '/rest/ui/environments/'.freeze
        READY        = '/rest/v1/peer/ready'.freeze
      end
      LOGIN = '/login'.freeze
      DEFAULT_PASSWORDS = 'secret'.freeze
    end

    module Gorjun
      INFO_DEV    = 'https://devcdn.subutai.io:8338/kurjun/rest/template/info'.freeze
      INFO_MASTER = 'https://mastercdn.subutai.io:8338/kurjun/rest/template/info'.freeze
      INFO_PROD   = 'https://cdn.subutai.io:8338/kurjun/rest/template/info'.freeze
    end

    module Bazaar
      BASE_DEV    = 'https://devbazaar.subutai.io'.freeze
      BASE_MASTER = 'https://masterbazaar.subutai.io'.freeze
      BASE_PROD   = 'https://bazaar.subutai.io'.freeze

      module V1
        PEER  = '/rest/v1/tray/peers/{FINGERPRINT}'.freeze
        LOGIN = '/rest/v1/client/login'.freeze
        ENVIRONMENTS = '/rest/v1/client/environments'.freeze
        LOG = '/rest/v1/client/environments/{SUBUTAI_ID}'.freeze
        DOMAIN_RESERVE = '/rest/v1/client/domains/{DOMAIN}'
        VARIABLES = '/rest/v1/client/blueprint/variables'.freeze
        BLUEPRINT = '/rest/v1/client/blueprint/build'.freeze
        DOMAIN_LIST  = '/rest/v1/client/domains'.freeze
      end
    end

    module Blueprint
      FILE_NAME = 'Subutai.json'.freeze
      ATTEMPT = 10.freeze
    end

    module EnvironmentState
      FAILED    = 'FAILED'.freeze
      SUCCEEDED = 'SUCCEEDED'.freeze
      HEALTHY   = 'HEALTHY'.freeze
      UNHEALTHY = 'UNHEALTHY'.freeze
    end

    module CommandState
      SUCCEEDED = 'SUCCEEDED'.freeze
      FAILED  = 'FAILED'.freeze
      KILLED  = 'KILLED'.freeze
      TIMEOUT = 'TIMEOUT'.freeze
    end

    module ApplicationState
      INSTALLING = 'INSTALLING'.freeze
      INSTALLED  = 'INSTALLED'.freeze
    end

    module SubutaiAgentCommand
      BASE   = 'sudo /snap/bin/subutai'.freeze
      UPDATE = ' update'.freeze                     # arg required
      LOG    = ' log'.freeze
      INFO   = ' info'.freeze                       # arg required
      LIST   = ' list'.freeze
      TEMPLATE_IMPORT = ' import ubuntu16'.freeze
      TEMPLATE_CLONE  = ' clone ubuntu16'.freeze    # arg required
      TEMPLATE_ATTACH = ' attach'.freeze            # arg required
      TEMPLATE_EXPORT = ' export'.freeze            # arg required
    end
  end
end