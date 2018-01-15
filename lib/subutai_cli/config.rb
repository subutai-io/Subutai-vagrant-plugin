require 'vagrant'

module SubutaiCommands
  UPDATE = "sudo /snap/bin/subutai update"
  LOG = "sudo /snap/bin/subutai log"
end

module SubutaiAPI
  TOKEN = "/rest/v1/identity/gettoken"
  REGISTER_HUB = "/rest/v1/hub/register?sptoken="
end



module SubutaiCli
  module Subutai
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :url

      def initialize
        super
        @url = UNSET_VALUE
      end

      def finalize!
        @url = "" if @url == UNSET_VALUE
      end
    end
  end
end