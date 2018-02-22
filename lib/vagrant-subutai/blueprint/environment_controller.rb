require_relative '../../vagrant-subutai'
require 'base64'

module VagrantSubutai
  module Blueprint
    class EnvironmentController
      attr_accessor :name,        # Environment name
                    :ansible,     # Environment ansible configurations
                    :log,         # Environment build logs
                    :id,          # Environment build id
                    :tracker_id   # Environment logs tracker id

      def build(url,token, rh_id, peer_id)
        variable = Blueprint::VariablesController.new("#{Dir.pwd}/#{Configs::Blueprint::FILE_NAME}")

        if variable.has_ansible?
          @ansible = variable.ansible
        end

        params = variable.params(rh_id, peer_id)
        @name = params['name']

        response = Rest::SubutaiConsole.environment(url, token, params.to_json)

        case response
          when Net::HTTPAccepted
            json = JSON.parse(response.body)

            @id          = json['environmentId']
            @tracker_id  = json['trackerId']

            @log = VagrantSubutai::Rest::SubutaiConsole.log(url, token, @tracker_id)
            @log = JSON.parse(@log.body)

            decoded_log = Base64.decode64(@log['log'])
            logs = decoded_log.split(/\{(.*?)\}\,/)

            @logs_last_index = nil # this saves last logs index (for not showing duplicated logs)
            @temp_last_index = nil

            logs.each_with_index do |v, i|
              STDOUT.puts v
              @temp_last_index = i
            end

            @logs_last_index = @temp_last_index

            until @log['state'] == Configs::EnvironmentState::SUCCEEDED || @log['state'] == Configs::EnvironmentState::FAILED

              @log = VagrantSubutai::Rest::SubutaiConsole.log(url, token, @tracker_id)
              @log = JSON.parse(@log.body)

              decoded_log = Base64.decode64(@log['log'])
              logs = decoded_log.split(/\{(.*?)\}\,/)

              logs.each_with_index do |v, i|
                if @logs_last_index < i
                  STDOUT.puts v
                end
                @temp_last_index = i
              end


              @logs_last_index = @temp_last_index
            end

            STDOUT.puts "\nBlueprint environment #{@name} state: #{@log['state']}"
          else
            STDOUT.puts STDERR.puts "Error: #{response.body}"
        end
      end
    end
  end
end