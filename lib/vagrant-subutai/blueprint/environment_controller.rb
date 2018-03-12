require_relative '../../vagrant-subutai'
require 'base64'
require 'json'


module VagrantSubutai
  module Blueprint
    class EnvironmentController
      attr_accessor :name,          # Environment name
                    :ansible,       # Environment ansible configurations
                    :log,           # Environment build logs
                    :id,            # Environment build id
                    :tracker_id,    # Environment logs tracker id
                    :container_ids, # Container Hash {'hostname' => id}
                    :peer_os_token  # Peer Os token

      def build(url, token, rh_id, peer_id, mode)

        variable = VagrantSubutai::Blueprint::VariablesController.new(@free_ram, @free_disk, mode)
        variable.cookies = token       # needs cookies while reserving domain to Bazaar
        variable.check_required_quota

        if mode == Configs::Blueprint::MODE::PEER
          variable.user_variables

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

                begin
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
                rescue JSON::ParserError => e
                  Put.error e
                end

                sleep 5 # sleep 5 seconds
              end

              if @log['state'] == Configs::EnvironmentState::SUCCEEDED
                Put.success "\nEnvironment State: #{@log['state']}"

                if variable.has_ansible?
                  env = list(url, token)

                  ansible = VagrantSubutai::Blueprint::AnsibleController.new(@ansible, env, url, token)
                  ansible.hosts
                  ansible.download
                  ansible.run
                else
                  list(url, token)
                end

                domain = variable.domain
                unless domain.nil?
                  response = VagrantSubutai::Rest::SubutaiConsole.domain(url, token, @id, domain.name)

                  case response
                    when Net::HTTPOK

                      response = VagrantSubutai::Rest::SubutaiConsole.port(url, token, @id, @container_ids[domain.container_hostname], domain.internal_port)

                      unless response.code == 200
                        Put.error response.message
                        Put.error response.body
                      end
                      ip = url.gsub("https://", "")
                      ip = ip.gsub(':8443', '')

                      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
                        Put.warn "MESSAGE You're environment has been setup for a *local* #{domain.name}. You can map this domain to the IP address #{ip} in your C:\\Windows\\System32\\drivers\\etc\\hosts file or to your local DNS."
                      else
                        Put.warn "MESSAGE You're environment has been setup for a *local* #{domain.name}. You can map this domain to the IP address #{ip} in your /etc/hosts file or to your local DNS."
                      end
                    else
                      Put.error response.body
                      Put.error response.code
                      Put.error response.message
                  end
                end
              else
                Put.error "\nEnvironment State: #{@log['state']}"
              end
            else
              Put.error "Error: #{response.body}"
          end
        elsif mode == Configs::Blueprint::MODE::BAZAAR
          # Bazaar new REST API to build blueprint provisioning
          response = VagrantSubutai::Rest::Bazaar.variables(variable.json, peer_id, token)

          case response
            when Net::HTTPOK
              variables = JSON.parse(response.body)
              params = []

              variables.each do |var|
                temp = var
                temp['value'] = variable.get_input_bazaar(var)
                params << temp
              end

              response = Rest::Bazaar.blueprint(variable.json, params, peer_id, token)

              case response
                when Net::HTTPAccepted
                  json = JSON.parse(response.body)
                  hub_id = json['hubId']
                  subutai_id = json['subutaiId']
                  @id = subutai_id

                  Put.warn "\nStarted environment building ...... \n"

                  # Track environment create state logs
                  @log = Rest::Bazaar.log(token, subutai_id)
                  @log = JSON.parse(@log.body)
                  timer = Time.now + (60 * 60 * 17) # 17 hours
                  @last_peer_state = nil

                  until (@log['environment_status'] == Configs::EnvironmentState::HEALTHY || @log['environment_status'] == Configs::EnvironmentState::UNHEALTHY) && Time.now <= timer
                    @log = Rest::Bazaar.log(token, subutai_id)

                    begin
                      @log = JSON.parse(@log.body)
                      environment_peers = @log['environment_peers']

                      environment_peers.each_with_index do |v, i|
                        if (@last_peer_state != v['peer_state'])
                          Put.info v['peer_state']
                          Put.info v['peer_message']
                        end
                        @last_peer_state = v['peer_state']
                      end

                    rescue JSON::ParserError => e
                      Put.error e
                    end

                    sleep 5 # sleep 5 seconds
                  end

                  if @log['environment_status'] == Configs::EnvironmentState::HEALTHY
                    Put.success "\nEnvironment State: #{@log['environment_status']}"
                    # Track ansible logs

                    unless @log['environment_applications'].empty?
                      arr = @log['environment_applications']

                      arr.each_with_index  do |environment_application, i|
                        @tmp = nil

                        until (@log['environment_applications'][i])['application_state'] == Configs::ApplicationState::INSTALLED
                          @log = Rest::Bazaar.log(token, subutai_id)

                          begin
                            @log = JSON.parse(@log.body)

                            if @tmp.nil?
                              Put.info (@log['environment_applications'][i])['application_log']
                            else
                              msg = (@log['environment_applications'][i])['application_log']
                              if @tmp.length < msg.length
                                msg = msg[(@tmp.length)..(msg.length-1)]
                                Put.info msg
                              end
                            end
                            @tmp = (@log['environment_applications'][i])['application_log']

                          rescue JSON::ParserError => e
                            Put.error e
                          end

                          sleep 5 # sleep 5 seconds
                        end
                      end
                    end
                  elsif @log['environment_status'] == Configs::EnvironmentState::UNHEALTHY
                    Put.error "\nEnvironment State: #{@log['environment_status']}"
                  elsif timer < Time.now
                    Put.error "\nEnvironment State: Timeout environment creating"
                  else
                    Put.error "\nEnvironment State: #{@log['environment_status']}"
                  end
                else
                  Put.error response.body
              end
            else
              Put.error response.body
              Put.error response.message
          end
        end
      end

      # Checks peer available resource ram, disk
      def check_free_quota(resource)
        resource = JSON.parse(resource)

        @free_ram = resource['RAM']['free'].to_f / 1073741824                                       # convert bytes to gb
        @free_disk = (resource['Disk']['total'].to_f - resource['Disk']['used'].to_f) / 1073741824  # convert bytes to gb
      end

      # Gets Environment from Subutai Console REST API
      def list(url, token)
        env = VagrantSubutai::Models::Console::Environment.new
        response = VagrantSubutai::Rest::SubutaiConsole.environments(url, token)

        @container_ids = {}

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
                    cont.environmentId = container['environmentId']
                    cont.hostname      = container['hostname']
                    cont.ip            = container['ip']
                    cont.templateName  = container['templateName']
                    cont.templateId    = container['templateId']
                    cont.type          = container['type']
                    cont.arch          = container['arch']
                    cont.peerId        = container['peerId']
                    cont.hostId        = container['hostId']
                    cont.local         = container['local']
                    cont.state         = container['state']
                    cont.rhId          = container['rhId']
                    cont.quota         = container['quota']
                    cont.dataSource    = container['dataSource']
                    cont.containerName = container['containerName']
                    @container_ids[cont.hostname] = cont.id

                    env.containers << cont
                  end
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