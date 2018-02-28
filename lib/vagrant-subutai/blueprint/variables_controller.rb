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
                    :available_disk        # sum of all containers disk size free (in unit GB)

      # @params path
      def initialize(available_ram, available_disk)
        @required_ram   = 0
        @required_disk  = 0
        @available_ram = available_ram
        @available_disk = available_disk

        begin
          @json = JSON.parse(File.read("#{Dir.pwd}/#{Configs::Blueprint::FILE_NAME}"))
        rescue => e
          Put.error e
        end
      end

      # Gives Subutai.json user variables
      # returns json object
      def user_variables
        hash = {}

        if @json.key?('user-variables')
          user_variables = @json['user-variables']
          keys = user_variables.keys

          keys.each do |key|
            hash[key] = get_input(user_variables[key])
          end
        end

        hash
      end

      # This counts how mach quota(ram, disk) required for building environment from the Peer Os
      def check_required_quota
        if @json.key?('user-variables')
          user_variables = @json['user-variables']
          keys = user_variables.keys

          keys.each do |key|
            if user_variables[key]['type'] == 'enum'
              @required_ram  += VagrantSubutai::Configs::Quota::RESOURCE[user_variables[key]['default']]['RAM']
              @required_disk += VagrantSubutai::Configs::Quota::RESOURCE[user_variables[key]['default']]['DISK']
            end
          end

          @required_ram  += VagrantSubutai::Configs::Quota::RESOURCE['TINY']['RAM'] if @json.key?('ansible-configuration')  # default ansible container ram
          @required_disk += VagrantSubutai::Configs::Quota::RESOURCE['TINY']['DISK'] if @json.key?('ansible-configuration') # default ansible container disk
        end
      end

      def has_ansible?
        if @json.key?('ansible-configuration')
          true
        else
          false
        end
      end

      def ansible
        @variables = user_variables

        if has_ansible?
          ansible = VagrantSubutai::Models::Ansible.new
          ansible_configuration = @json['ansible-configuration']

          ansible.ansible_playbook = ansible_configuration['ansible-playbook']
          ansible.source_url = ansible_configuration['source-url']
          ansible.extra_vars = []
          ansible.groups = []

          ansible_configuration['groups'].each do |group|
            temp = group
            hostnames = []

            group['hostnames'].each do |hostname|
              hostnames << value(hostname)
            end
            temp['hostnames'] = hostnames
            ansible.groups << temp
          end

          if ansible_configuration.key?('extra-vars')
            ansible_configuration['extra-vars'].each do |obj|
              hash = {}
              hash[obj['key']] = value(obj['value'])
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

        containers.each do |container|
          node = {}
          node['hostname'] = container.hostname
          node['quota'] = {'containerSize' => container.container_size}
          node['templateId'] = Rest::Gorjun.template_id(container.name, container.owner)
          node['resourceHostId'] = rh_id
          node['peerId'] = peer_id
          nodes << node
        end

        hash['name'] = env.name
        hash['sshKey'] = ""
        hash['nodes'] = nodes

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
        env.name = value(@json['name'])
        env.containers = containers
        env
      end

      # Containers
      # @return Container Models
      def containers
        arr = []

        @json['containers'].each do |container|
          cont = VagrantSubutai::Models::Container.new

          cont.hostname = value(container['hostname'])
          cont.container_size = value(container['size'])
          cont.template = container['template']
          cont.peer_criteria = container['peer-criteria']
          cont.port_mapping = container['port-mapping']

          arr << cont
        end

        if @json.key?('ansible-configuration')
          cont = VagrantSubutai::Models::Container.new
          cont.ansible
          arr << cont
        end

        arr
      end

      # Gets input variable
      # @params variable json object
      def get_input(variable_json)
        Put.info "\n#{variable_json['description']}: (Ex: #{variable_json['default']})"

        if variable_json['type'] == 'enum'
          Put.info "\nEnter your container size (Ex: #{variable_json['default']}): "
          validations = variable_json['validation'].split(',')

          temp = nil
          validations.each_with_index do |validation, index|
            if @available_ram >= Configs::Quota::RESOURCE[validation]['RAM'] && @available_disk >= Configs::Quota::RESOURCE[validation]['DISK']
              Put.info "    #{index}. #{validation}"
              temp = index
            end
          end

          Put.info "\nChoose your container size between ( 0 to #{temp}): "
          input = STDIN.gets.strip.to_i
          validations[input]
        else
          STDIN.gets.strip
        end
      end

      # Validate variable
      # @params var, type, validation
      def validate_variable(var, variable_json)
        if (var =~ /#{Regexp.quote(variable_json['validation'])}/).nil?
          false
        else
          true
        end
      end

      # Validates Subutai.json file
      def validate
        scheme = Configs::Blueprint::SCHEME

        # Check keys
        @json.keys.each do |key|
          unless scheme.key?(key.to_sym)
            Put.error "Undefined key \"#{key}\""
            return false
          end
        end

        scheme_container = scheme[:containers].first
        # Check container keys
        @json['containers'].each do |container|
          container.keys.each do |key|
            unless scheme_container.key?(key.to_sym)
              Put.error "Undefined key \"#{key}\""
            end
          end
        end


      end
    end
  end
end