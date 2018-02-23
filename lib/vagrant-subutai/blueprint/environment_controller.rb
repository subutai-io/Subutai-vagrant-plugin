require_relative '../../vagrant-subutai'
require 'base64'
require 'json'

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

              if variable.has_ansible?
                env = list(url, token)
                ansible = VagrantSubutai::Blueprint::AnsibleController.new(@ansible, env)
                ansible.hosts
                ansible.run

                Put.warn @ansible.context
              end
            else
              Put.error "\nEnvironment State: #{@log['state']}"
            end
          else
            Put.error "Error: #{response.body}"
        end
      end

      # Gets Environment from Subutai Console REST API
      def list(url, token)
        env = VagrantSubutai::Models::Console::Environment.new
        response = VagrantSubutai::Rest::SubutaiConsole.environments(url, token)

        case response
          when Net:: HTTPOK
            environments = JSON.parse(response.body)
            environments.each do |environment|
              if environment['id'] == @id
                env.id = @id
                env.name = environment['name']
                env.status = environment['status']
                env.containers = []

                environment['containers'].each do |container|

                  if container['templateName'] == VagrantSubutai::Configs::Ansible::TEMPLATE_NAME
                    env.ansible_host_id         = container['id']
                    env.ansible_container_state = container['state']
                  else
                    cont = VagrantSubutai::Models::Console::Container.new
                    cont.id            = container['id']
                    cont.hostId        = container['hostId']
                    cont.hostname      = container['hostName']
                    cont.arch          = container['arch']
                    cont.containerName = container['containerName']
                    cont.ip            = container['ip']
                    cont.templateId    = container['templateId']
                    cont.templateName  = container['templateName']
                    cont.quota         = container['quota']
                    cont.environmentId = container['environmentId']
                    cont.peerId        = container['peerId']
                    cont.dataSource    = container['dataSource']
                    cont.local         = container['local']
                    cont.state         = container['state']
                    cont.rhId          = container['rhId']
                    cont.type          = container['type']
                  end

                  env.containers << cont
                end
              end
            end
          else
            Put.error response.body
            raise 'Can\'t get Environment lists from Subutai Console'
        end

        env
      end
    end
  end
end