require_relative '../../vagrant-subutai'

module VagrantSubutai
  module Blueprint
    class EnvironmentController
      def build(rh_id, peer_id)
        variable = Blueprint::VariablesController.new("#{Dir.pwd}/#{Configs::Blueprint::FILE_NAME}")

        variable.params(rh_id, peer_id)
      end
    end
  end
end