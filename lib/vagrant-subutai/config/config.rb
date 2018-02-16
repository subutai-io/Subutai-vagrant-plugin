module VagrantSubutai
  module Config
    module VagrantCommand
      INIT = "vagrant init"
      UP = "vagrant up"
      RH_UP = "SUBUTAI_PEER=false vagrant up"
      PROVISION = "vagrant provision"
      SUBUTAI_ID = "vagrant subutai --info id"
      ARG_IP_ADDR = "ipaddr"
    end

    module SubutaiConsoleAPI
      PORT = "8443"
      module V1
        TOKEN = "/rest/v1/identity/gettoken"
        REGISTER_HUB = "/rest/v1/hub/register?sptoken="
        APPROVE = "/rest/v1/registration/requests"
        FINGERPRINT = "/rest/v1/security/keyman/getpublickeyfingerprint"
        REQUESTS = "/rest/v1/registration/requests?sptoken="
      end
    end

    module Blueprint
      FILE_NAME = "Subutai.json"
    end

    module SubutaiAgentCommand
      BASE = "sudo /snap/bin/subutai"
      UPDATE = " update"                   # arg required
      LOG = " log"
      INFO = " info"                       # arg required
      TEMPLATE_IMPORT = " import ubuntu16"
      TEMPLATE_CLONE = " clone ubuntu16"   # arg required
      TEMPLATE_ATTACH = " attach"          # arg required
      TEMPLATE_EXPORT = " export"          # arg required
      LIST = " list"
    end
  end
end