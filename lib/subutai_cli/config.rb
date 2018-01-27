require_relative '../subutai_cli'

module SubutaiAgentCommand
  if $SUBUTAI_ENV.nil?
    ENV = 'subutai'
  else
    ENV = 'subutai-' + $SUBUTAI_ENV
  end
  BASE = 'sudo /snap/bin/' + ENV
  UPDATE = BASE + ' update'                   # arg required
  LOG = BASE + ' log'
  INFO = BASE + ' info'                       # arg required
  TEMPLATE_IMPORT = BASE + ' import ubuntu16'
  TEMPLATE_CLONE = BASE + ' clone ubuntu16'   # arg required
  TEMPLATE_ATTACH = BASE + ' attach'          # arg required
  TEMPLATE_EXPORT = BASE + ' export'          # arg required
  LIST = BASE + ' list'
end

module SubutaiConsoleAPI
  PORT = '8443'
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