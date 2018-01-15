require 'vagrant'

module SubutaiCommands
  UPDATE = "sudo /snap/bin/subutai update"                   # name params required
  LOG = "sudo /snap/bin/subutai log"
  TEMPLATE_IMPORT = "sudo /snap/bin/subutai import ubuntu16"
  TEMPLATE_CLONE = "sudo /snap/bin/subutai clone ubuntu16"   # name params required
  TEMPLATE_ATTACH = "sudo /snap/bin/subutai attach"          # name params required
  TEMPLATE_EXPORT = "sudo /snap/bin/subutai export"          # name params required
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