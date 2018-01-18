require_relative '../subutai_cli'

module SubutaiAgentCommand
  UPDATE = 'sudo /snap/bin/subutai update'                   # name params required
  LOG = 'sudo /snap/bin/subutai log'
  INFO_ID = 'sudo /snap/bin/subutai info id'
  TEMPLATE_IMPORT = 'sudo /snap/bin/subutai import ubuntu16'
  TEMPLATE_CLONE = 'sudo /snap/bin/subutai clone ubuntu16'   # name params required
  TEMPLATE_ATTACH = 'sudo /snap/bin/subutai attach'          # name params required
  TEMPLATE_EXPORT = 'sudo /snap/bin/subutai export'          # name params required
end

module SubutaiConsoleAPI
  module V1
    TOKEN = '/rest/v1/identity/gettoken'
    REGISTER_HUB = '/rest/v1/hub/register?sptoken='
    APPROVE = '/rest/v1/registration/requests'
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
  RH_UP = 'SUBUTAI_PEER=false vagrant up'
  PROVISION = 'vagrant provision'
end