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

    module Environment
      PROD   = 'prod'.freeze
      DEV    = 'dev'.freeze
      SYSNET = 'sysnet'.freeze
      MASTER = 'master'.freeze
    end

    module SubutaiConsoleAPI
      PORT    = '8443'.freeze
      COMMAND = '/rest/ui/commands?sptoken='.freeze

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
      end
    end

    module Gorjun
      INFO_DEV    = 'https://devcdn.subut.ai:8338/kurjun/rest/template/info'.freeze
      INFO_MASTER = 'https://mastercdn.subut.ai:8338/kurjun/rest/template/info'.freeze
      INFO_PROD   = 'https://cdn.subut.ai:8338/kurjun/rest/template/info'.freeze
    end

    module Blueprint
      FILE_NAME = 'Subutai.json'.freeze
    end

    module EnvironmentState
      FAILED    = 'FAILED'.freeze
      SUCCEEDED = 'SUCCEEDED'.freeze
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