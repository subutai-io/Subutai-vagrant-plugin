require_relative '../../vagrant-subutai'

module VagrantSubutai
  module Blueprint
    class EnvironmentController
      def build(url,token, rh_id, peer_id)
        variable = Blueprint::VariablesController.new("#{Dir.pwd}/#{Configs::Blueprint::FILE_NAME}")

        params = variable.params(rh_id, peer_id)
        STDOUT.puts params

        response = Rest::SubutaiConsole.environment(url, token, params)

        case response
          when Net::HTTPAccepted
            puts "Successfully build blueprint!"
          else
            puts STDERR.puts "Error: #{response.body}"
        end
      end
    end
  end
end