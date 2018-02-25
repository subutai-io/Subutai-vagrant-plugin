require_relative '../../vagrant-subutai'
require 'json'

module VagrantSubutai
  module Blueprint
    class VariablesController
      attr_accessor :json, :variables

      # @params path
      def initialize(path)
        begin
          @json = JSON.parse(File.read(path))
          @variables = user_variables
        rescue JSON::ParserError => e
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

      def has_ansible?
        if @json.key?('ansible-configuration')
          true
        else
          false
        end
      end

      def ansible
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
          validations.each_with_index do |validation, index|
            Put.info "    #{index}. #{validation}"
          end
          Put.info "\nChoose your container size between ( 0 to n): "
          input = STDIN.gets.strip.to_i
          validations[input]
        else
          STDIN.gets.strip
        end
      end

      # Validate variable
      # @params var, type, validation
      def validate(var, variable_json)
        if (var =~ /#{Regexp.quote(variable_json['validation'])}/).nil?
          false
        else
          true
        end
      end
    end
  end
end