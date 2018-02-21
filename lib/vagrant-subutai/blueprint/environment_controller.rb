require_relative '../../vagrant-subutai'
require 'base64'

module VagrantSubutai
  module Blueprint
    class EnvironmentController
      attr_accessor :name, :ansible, :log

      def build(url,token, rh_id, peer_id)
        variable = Blueprint::VariablesController.new("#{Dir.pwd}/#{Configs::Blueprint::FILE_NAME}")

        if variable.has_ansible?
          @ansible = variable.ansible
        end

        params = variable.params(rh_id, peer_id)
        puts "topology: #{params}"
        @name = params['name']

        response = Rest::SubutaiConsole.environment(url, token, params)

        case response
          when Net::HTTPAccepted
            json = JSON.parse(response.body)
            environment_id = json['environmentId']
            tracker_id = json['trackerId']

            puts "tracker_id: " + tracker_id
            puts "environment_id: " + environment_id

            @log = VagrantSubutai::Rest::SubutaiConsole.log(url, token, tracker_id)
            @log = JSON.parse(@log.body)
            puts "#{@log['state']}"
            decoded_log = Base64.decode64(@log['log'])
            puts decoded_log

            until @log['state'] == "SUCCEEDED" || @log['state'] == "FAILED"

              #puts "id: #{log['id']}"
              #puts "description: #{log['description']}"
              #puts "#{decoded_log}"
              puts "state: #{@log['state']}"
              #puts "createDate: #{log['createDate']}"
              #puts "source: #{log['source']}"
              @log = VagrantSubutai::Rest::SubutaiConsole.log(url, token, tracker_id)
              @log = JSON.parse(@log.body)
              decoded_log = Base64.decode64(@log['log'])
              puts "while: #{decoded_log}"
            end

            puts "Successfully build blueprint!"
            puts "Resonse body: #{json}"
            #puts "Ansible: #{@ansible.context}"
          else
            puts STDERR.puts "Error: #{response.body}"
        end
      end
    end
  end
end