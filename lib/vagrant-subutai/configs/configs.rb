module VagrantSubutai
  module Configs
    module VagrantCommand
      INIT = 'vagrant init'.freeze
      UP = 'vagrant up'.freeze
      RH_UP = 'SUBUTAI_PEER=false vagrant up'.freeze
      PROVISION = 'vagrant provision'.freeze
      SUBUTAI_ID = 'vagrant subutai --info id'.freeze
      ARG_IP_ADDR = 'ipaddr'.freeze
    end

    module SubutaiConsoleAPI
      PORT = '8443'.freeze
      module V1
        TOKEN = '/rest/v1/identity/gettoken'.freeze
        REGISTER_HUB = '/rest/v1/hub/register?sptoken='.freeze
        APPROVE = '/rest/v1/registration/requests'.freeze
        FINGERPRINT = '/rest/v1/security/keyman/getpublickeyfingerprint'.freeze
        REQUESTS = '/rest/v1/registration/requests?sptoken='.freeze
        ENVIRONMENT = '/rest/v1/environments?sptoken='.freeze
      end
    end

    module Gorjun
      INFO = 'https://cdn.subut.ai:8338/kurjun/rest/template/info'.freeze
    end

    module Blueprint
      FILE_NAME = 'Subutai.json'.freeze
    end

    module SubutaiAgentCommand
      BASE = 'sudo /snap/bin/subutai'.freeze
      UPDATE = ' update'.freeze                   # arg required
      LOG = ' log'.freeze
      INFO = ' info'.freeze                       # arg required
      TEMPLATE_IMPORT = ' import ubuntu16'.freeze
      TEMPLATE_CLONE = ' clone ubuntu16'.freeze   # arg required
      TEMPLATE_ATTACH = ' attach'.freeze          # arg required
      TEMPLATE_EXPORT = ' export'.freeze          # arg required
      LIST = ' list'.freeze
    end
  end
end