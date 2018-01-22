require_relative '../subutai_cli'

module SubutaiAgentCommand
  UPDATE = 'sudo /snap/bin/subutai update'                   # arg required
  LOG = 'sudo /snap/bin/subutai log'
  INFO = 'sudo /snap/bin/subutai info'                            # arg required
  TEMPLATE_IMPORT = 'sudo /snap/bin/subutai import ubuntu16'
  TEMPLATE_CLONE = 'sudo /snap/bin/subutai clone ubuntu16'   # arg required
  TEMPLATE_ATTACH = 'sudo /snap/bin/subutai attach'          # arg required
  TEMPLATE_EXPORT = 'sudo /snap/bin/subutai export'          # arg required
  LIST = 'sudo /snap/bin/subutai list'
end

module SubutaiConsoleAPI
  module V1
    TOKEN = '/rest/v1/identity/gettoken'
    REGISTER_HUB = '/rest/v1/hub/register?sptoken='
    APPROVE = '/rest/v1/registration/requests'
    FINGERPRINT = '/rest/v1/security/keyman/getpublickeyfingerprint'
    REQUESTS = '/rest/v1/registration/requests?sptoken='
  end
end

module SubutaiCli
  module Subutai
    RH_FOLDER_NAME = 'RH'

    class Config < Vagrant.plugin('2', :config)
      attr_accessor :url

      def initialize
        super
        @url = UNSET_VALUE
      end

      def finalize!
        @url = '' if @url == UNSET_VALUE
      end
    end
  end
end

module VagrantCommand
  INIT = 'vagrant init'
  UP = 'vagrant up'
  RH_UP = 'SUBUTAI_PEER=false vagrant up'
  PROVISION = 'vagrant provision'
  SUBUTAI_ID = 'vagrant subutai --info id'
  ARG_IP_ADDR = 'ipaddr'
end