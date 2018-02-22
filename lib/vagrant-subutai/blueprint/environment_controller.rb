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
            Put.warn "Environment response #{response.body}"
            json = JSON.parse(response.body)

            Put.warn "\nStarted \"#{@name}\" environment building ...... \n"

            @id          = json['environmentId']
            @tracker_id  = json['trackerId']

            @log = VagrantSubutai::Rest::SubutaiConsole.log(url, token, @tracker_id)
            @log = JSON.parse(@log.body)

            decoded_log = Base64.decode64(@log['log'])
            logs = decoded_log.split(/\{(.*?)\}\,/)

            @logs_last_index = nil # this saves last logs index (for not showing duplicated logs)
            @temp_last_index = nil

            logs.each_with_index do |v, i|
              v = v.split(',')
              v.shift
              Put.info "#{v[1]}  #{v[0]}" unless v.empty?
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
                  v = v.split(',')
                  v.shift
                  Put.info "#{v[1]}  #{v[0]}" unless v.empty?
                end
                @temp_last_index = i
              end


              @logs_last_index = @temp_last_index
            end

            if @log['state'] == Configs::EnvironmentState::SUCCEEDED
              Put.success "\nEnvironment State: #{@log['state']}"

            else
              Put.error "\nEnvironment State: #{@log['state']}"
            end
          else
            Put.error "Error: #{response.body}"
        end
      end
    end
  end
end