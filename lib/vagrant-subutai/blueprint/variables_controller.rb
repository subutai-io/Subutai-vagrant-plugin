require_relative '../../vagrant-subutai'
require 'json'

module VagrantSubutai
  module Blueprint
    class VariablesController
      attr_accessor :json,
                    :variables,
                    :required_ram,         # sum of all containers ram size required (in unit GB)
                    :required_disk,        # sum of all containers disk size required (in unit GB)
                    :available_ram,        # sum of all containers ram size free (in unit GB)
                    :available_disk,       # sum of all containers disk size free (in unit GB)
                    :mode,                 # Environment build mode (peer, bazaar)
                    :cookies               # Bazaar cookies(for reserving domain)

      KEYS = {
               name:                  'name',
               description:           'description',
               containers:            'containers',
               hostname:              'hostname',
               template:              'template',
               size:                  'size',
               peer_criteria:         'peer-criteria',
               port_mapping:          'port-mapping',
               protocol:              'protocol',
               domain:                'domain',
               internal_port:         'internal-port',
               external_port:         'external-port',
               max_price:             'max-price',
               avg_cpu_load:          'avg-cpu-load',
               min_free_ram:          'min-free-ram',
               min_free_disk_space:   'min-free-disk-space',
               user_variables:        'user-variables',
               type:                  'type',
               default:               'default',
               validation:            'validation',
               ansible_configuration: 'ansible-configuration',
               extra_vars:            'extra-vars',
               key:                   'key',
               value:                 'value',
               source_url:            'source-url',
               ansible_playbook:      'ansible-playbook',
               groups:                'groups',
               hostnames:             'hostnames'
             }.freeze

      # @params available_ram, available_disk
      def initialize(available_ram, available_disk, mode)
        @required_ram   = 0
        @required_disk  = 0
        @available_ram  = available_ram
        @available_disk = available_disk
        @mode = mode

        begin
          @json = JSON.parse(File.read("#{Dir.pwd}/#{Configs::Blueprint::FILE_NAME}"))
        rescue => e
          Put.error e
          exit!
        end
      end

      # Gives Subutai.json user variables
      # returns json object
      def user_variables
        hash = {}

        if @json.key?(KEYS[:user_variables])
          conf_user_variables = SubutaiConfig.get(:USER_VARIABLES)

          if conf_user_variables.nil?
            conf_user_variables = {}
          else
            if conf_user_variables.kind_of?(String)
              begin
                conf_user_variables = JSON.parse(SubutaiConfig.get(:USER_VARIABLES))
              rescue JSON::ParserError => e
                Put.error e
                return
              end
            end
          end

          user_variables = @json[KEYS[:user_variables]]
          keys = user_variables.keys

          keys.each do |key|
            if conf_user_variables[key].nil?
              hash[key] = get_input(user_variables[key])
            else
              hash[key] = conf_user_variables[key]
            end
          end
        end

        @variables = hash
      end

      # This counts how mach quota(ram, disk) required for building environment from the Peer Os
      def check_required_quota
        if @json.key?(KEYS[:user_variables])
          user_variables = @json[KEYS[:user_variables]]
          keys = user_variables.keys

          keys.each do |key|
            if user_variables[key][KEYS[:type]] == 'enum' && Configs::Blueprint::CONTAINER_SIZES.include?(user_variables[key][KEYS[:default]])
              @required_ram  += (VagrantSubutai::Configs::Quota::RESOURCE[(user_variables[key][KEYS[:default]]).strip.to_sym][:RAM])
              @required_disk += (VagrantSubutai::Configs::Quota::RESOURCE[(user_variables[key][KEYS[:default]]).strip.to_sym][:DISK])
            end
          end

          @required_ram  += VagrantSubutai::Configs::Quota::RESOURCE[:TINY][:RAM] if @json.key?(KEYS[:ansible_configuration])  # default ansible container ram
          @required_disk += VagrantSubutai::Configs::Quota::RESOURCE[:TINY][:DISK] if @json.key?(KEYS[:ansible_configuration]) # default ansible container disk
        else
          @json[KEYS[:containers]].each do |container|
            @required_ram  += (VagrantSubutai::Configs::Quota::RESOURCE[(container[KEYS[:size]]).to_sym][:RAM])
            @required_disk += (VagrantSubutai::Configs::Quota::RESOURCE[(container[KEYS[:size]]).to_sym][:DISK])
          end
        end
      end

      def check_quota?(resource)
        resource = JSON.parse(resource)

        @free_ram = resource['RAM']['free'].to_f / 1073741824                                       # convert bytes to gb
        @free_disk = (resource['Disk']['total'].to_f - resource['Disk']['used'].to_f) / 1073741824  # convert bytes to gb

        @free_ram = @free_ram.round(3)
        @free_disk = @free_disk.round(2)

        check_required_quota

        if @free_ram >= @required_ram && @free_disk >= @required_disk
          true
        else
          Put.warn "\nNo available resources on the Peer Os\n"
          Put.info "--------------------------------------------------------------------"
          if @free_ram >= @required_ram
            Put.info "RAM:  available = #{@free_ram} gb, required minimum = #{@required_ram} gb"
          else
            Put.error "RAM:  available = #{@free_ram} gb, required minimum = #{@required_ram} gb"
          end

          Put.info "--------------------------------------------------------------------"

          if @free_disk >= @required_disk
            Put.info "DISK:  available = #{@free_disk} gb, required minimum = #{@required_disk} gb"
          else
            Put.error "DISK:  available = #{@free_disk} gb, required minimum = #{@required_disk} gb"
          end
          Put.info "--------------------------------------------------------------------"

          false
        end
      end

      def has_ansible?
        if @json.key?(KEYS[:ansible_configuration])
          true
        else
          false
        end
      end

      def ansible

        if has_ansible?
          ansible = VagrantSubutai::Models::Ansible.new
          ansible_configuration = @json[KEYS[:ansible_configuration]]

          ansible.ansible_playbook = ansible_configuration[KEYS[:ansible_playbook]]
          ansible.source_url = ansible_configuration[KEYS[:source_url]]
          ansible.extra_vars = []
          ansible.groups = []

          ansible_configuration[KEYS[:groups]].each do |group|
            temp = group
            hostnames = []

            group[KEYS[:hostnames]].each do |hostname|
              hostnames << value(hostname)
            end
            temp[KEYS[:hostnames]] = hostnames
            ansible.groups << temp
          end

          if ansible_configuration.key?(KEYS[:extra_vars])
            ansible_configuration[KEYS[:extra_vars]].each do |obj|
              hash = {}
              hash[obj[KEYS[:key]]] = value(obj[KEYS[:value]])
              ansible.extra_vars << hash
            end
          end

          ansible
        end
      end

      def params(rh_id, peer_id)
        env = environment
        containers = env.containers

        hash = {}
        nodes = []

        if mode == Configs::Blueprint::MODE::PEER
          containers.each do |container|
            node = {}
            node['hostname'] = container.hostname
            node['quota'] = {'containerSize' => container.container_size}
            node['templateId'] = Rest::Bazaar.template_id(container.name, container.owner)
            node['resourceHostId'] = rh_id
            node['peerId'] = peer_id
            nodes << node
          end

          hash['name'] = env.name
          hash['sshKey'] = ""
          hash['nodes'] = nodes
        elsif mode == Configs::Blueprint::MODE::BAZAAR
          containers.each do |container|
            node = {}
            node['hostname'] = container.hostname
            node['quota'] = {'containerSize' => container.container_size}
            node['templateId'] = Rest::Bazaar.template_id(container.name, container.owner)
            node['resourceHostId'] = rh_id
            node['templateName'] = container.name
            node['peerId'] = peer_id
            nodes << node
          end

          hash['environmentName'] = env.name
          hash['exchangeSshKeys'] = true
          hash['registerHosts'] = true
          hash['nodes'] = nodes
        end


        hash
      end

      def value(variable)
        if is_variable?(variable)
          @variables[variable[/\${(.*?)}/, 1]]
        else
          variable
        end
      end

      def is_variable?(var)
        if (var =~ /\${(.*?)}/).nil?
          false
        else
          true
        end
      end

      # Environment
      # @return Environment model
      def environment
        env = VagrantSubutai::Models::Environment.new
        env.name = value(@json[KEYS[:name]])
        env.containers = containers
        env
      end

      # Containers
      # @return Container Models
      def containers
        arr = []

        @json[KEYS[:containers]].each do |container|
          cont = VagrantSubutai::Models::Container.new

          cont.hostname = value(container[KEYS[:hostname]])
          cont.container_size = value(container[KEYS[:size]])
          cont.template = container[KEYS[:template]]
          cont.peer_criteria = container[KEYS[:peer_criteria]]
          cont.port_mapping = container[KEYS[:port_mapping]]

          arr << cont
        end

        if @json.key?(KEYS[:ansible_configuration])
          cont = VagrantSubutai::Models::Container.new
          cont.ansible
          arr << cont
        end

        arr
      end

      # Domain
      # @return Domain Model or nil
      def domain
        @json[KEYS[:containers]].each do |container|
          if container.key?(KEYS[:port_mapping])
            container[KEYS[:port_mapping]].each do |port_map|
              if port_map[KEYS[:protocol]].downcase == 'http' || port_map[KEYS[:protocol]].downcase == 'tcp'
                domain = VagrantSubutai::Models::Domain.new

                domain.protocol = port_map[KEYS[:protocol]]
                domain.name = value(port_map[KEYS[:domain]])
                domain.internal_port = port_map[KEYS[:internal_port]]
                domain.external_port = port_map[KEYS[:external_port]]
                domain.container_hostname = value(container[KEYS[:hostname]])

                return domain
              end
            end
          end
        end

        nil
      end

      # Gets input variable
      # @params variable json object
      def get_input(variable_json)
        if variable_json[KEYS[:type]] == 'enum'
          Put.info "\n#{variable_json[KEYS[:description]]} (Ex: #{variable_json[KEYS[:default]]}): "
          validations = variable_json[KEYS[:validation]].split(',')

          temp = nil
          validations.each_with_index do |validation, index|
            if Configs::Blueprint::CONTAINER_SIZES.include?(validation) && @available_ram >= Configs::Quota::RESOURCE[validation.strip.to_sym][:RAM] && @available_disk >= Configs::Quota::RESOURCE[validation.strip.to_sym][:DISK]
              Put.info "    #{index}. #{validation}"
              temp = index
            else
              Put.info "    #{index}. #{validation}"
              temp = index
            end
          end

          Put.info "\nChoose your container size between ( 0 to #{temp}): "
          input = STDIN.gets.strip.to_i
          validations[input]
        elsif mode == Configs::Blueprint::MODE::BAZAAR && variable_json[KEYS[:type]] == 'domain'
          Put.info "\n#Create a new domain: (Ex: YOUR_DOMAIN_NAME.envs.subutai.cloud)"
          reserve
        else
          Put.info "\n#{variable_json[KEYS[:description]]}: (Ex: #{variable_json[KEYS[:default]]})"

          STDIN.gets.strip
        end
      end

      def reserve
        begin
          @temp = STDIN.gets.strip
          @response = VagrantSubutai::Rest::Bazaar.reserve(@cookies, @temp)

          until @response.kind_of?(Net::HTTPOK)
            Put.warn "\n-------------------------------------------------------------------"
            Put.warn "Requested \"#{@temp}.envs.subutai.cloud\" sub-domain already exists"
            Put.warn '-------------------------------------------------------------------'

            Put.info "\n#Create a new domain: (Ex: YOUR_DOMAIN_NAME.envs.subutai.cloud)"
            @temp = STDIN.gets.strip
            @response = VagrantSubutai::Rest::Bazaar.reserve(@cookies, @temp)
          end

          res = VagrantSubutai::Rest::Bazaar.domains(@cookies)
          json = JSON.parse(res.body)

          json = json.find {|domain| domain['name'].split('.').first == @temp}

          Put.info "\n Created a new domain: #{json['name']}"

          json['name']
        rescue => e
          Put.error e
        end
      end

      # Validate variable
      # @params var, type, validation
      def validate_variable(var, variable_json)
        if (var =~ /#{Regexp.quote(variable_json[KEYS[:validation]])}/).nil?
          false
        else
          true
        end
      end

      def bazaar_params(variables)
        variables.each do |variable|
          Put.info variable['label']
        end
      end

      def get_input_bazaar(variable)
        Put.info "\n#{variable['label']}"

        if variable['type'] == 'enum'
          arr = []
          arr = variable['acceptableValues'] if variable.key?('acceptableValues')
          temp = -1

          arr.each_with_index do |val, index|
            Put.info "     #{index}.  #{val}"
            temp = index
          end

          Put.info "\nChoose your container size between ( 0 to #{temp}): "
          input = STDIN.gets.strip.to_i
          arr[input]
        elsif variable['type'] == 'domain'
          arr = []
          arr = variable['acceptableValues'] if variable.key?('acceptableValues')
          temp = -1

          arr.each_with_index do |val, index|
            Put.info "     #{index}.  #{val}"
            temp = index
          end
          Put.info "     #{temp+1}.  Create a new domain: (Ex: YOUR_DOMAIN_NAME.envs.subutai.cloud)"

          Put.info "\nChoose options:  ( 0 to #{temp+1}) "
          input = STDIN.gets.strip.to_i

          if temp+1 == input
            Put.success "\nCreate a new domain: (Ex: YOUR_DOMAIN_NAME.envs.subutai.cloud)"
            reserve
          else
            Put.success "\n Chosen a domain: #{arr[input]}"
            arr[input]
          end
        else
          STDIN.gets.strip
        end
      end

      # Validates Subutai.json file
      def validate
        scheme = Configs::Blueprint::SCHEME

        # Check keys
        @json.keys.each do |key|
          unless scheme.key?(key.to_sym)
            Put.error "Undefined key: \"#{key}\""
            return false
          end
        end

        scheme_container = scheme[:containers].first
        scheme_port_mapping = scheme_container[KEYS[:port_mapping].to_sym].first
        # Check container keys
        @json[KEYS[:containers]].each do |container|
          container.keys.each do |key|
            unless scheme_container.key?(key.to_sym)
              Put.error "Undefined key: \"#{key}\""
              return false
            end

            if key == KEYS[:size] && !is_variable?(container[KEYS[:size]])
              unless Configs::Blueprint::CONTAINER_SIZES.include?(container[KEYS[:size]])
                Put.error "Undefined container size: #{container[KEYS[:size]]}"
                return false
              end
            end

            if container.key?(KEYS[:port_mapping])
              container[KEYS[:port_mapping]].each do |port_map|
                port_map.keys.each do |key|
                  unless scheme_port_mapping.key?(key.to_sym)
                    Put.error "Undefined port-mapping key: #{key}"
                    return false
                  end
                end
              end
            end
          end
        end

        # Check ansible configuration
        if @json.key?(KEYS[:ansible_configuration])
          @json[KEYS[:ansible_configuration]].keys.each do |key|
            unless scheme[KEYS[:ansible_configuration].to_sym].key?(key.to_sym)
              Put.error "Undefined ansible-configuration key: #{key}"
              return false
            end
          end

          # check extra-vars
          if @json[KEYS[:ansible_configuration]].key?(KEYS[:extra_vars])
            unless @json[KEYS[:ansible_configuration]][KEYS[:extra_vars]].kind_of?(Array)
              Put.error "ansible-configuration extra-vals should be JSON array \"[]\""
              return false
            end

            @json[KEYS[:ansible_configuration]][KEYS[:extra_vars]].each do |extra_var|
              unless extra_var.key?(KEYS[:key])
                Put.error "ansible-configuration extra-vals has no \"key\" key"
                return false
              end

              unless extra_var.key?(KEYS[:value])
                Put.error "ansible-configuration extra-vals has no \"value\" key"
                return false
              end
            end
          end

          # check groups
          if @json[KEYS[:ansible_configuration]].key?(KEYS[:groups])
            unless @json[KEYS[:ansible_configuration]][KEYS[:groups]].kind_of?(Array)
              Put.error "groups should be JSON array"
              return false
            end

            @json[KEYS[:ansible_configuration]][KEYS[:groups]].each do |group|
              group.keys.each do |key|
                unless scheme[KEYS[:ansible_configuration].to_sym][KEYS[:groups].to_sym].first.key?(key.to_sym)
                  Put.error "Undefined groups key: #{key}"
                  return false
                end
              end
            end
          end
        end

        # check peer criteria
        @json[KEYS[:peer_criteria]].each do |peer_criteria|
          peer_criteria.keys.each do |key|
            unless scheme[KEYS[:peer_criteria].to_sym].first.key?(key.to_sym)
              Put.error "Undefined peer-criteria key: #{key}"
              return false
            end
          end
        end

        # check user-variables
        if @json.key?(KEYS[:user_variables])
          @json[KEYS[:user_variables]].keys.each do |key|
            user_variable = @json[KEYS[:user_variables]][key]
            user_variable.keys.each do |key|
              unless scheme[KEYS[:user_variables].to_sym][:any_name].key?(key.to_sym)
                Put.error "Undefined user-variables key: #{key}"
                return false
              end
            end
          end
        end

        true
      end
    end
  end
end