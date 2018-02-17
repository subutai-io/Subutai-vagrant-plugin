require_relative '../../vagrant-subutai'
require 'json'

module VagrantSubutai
  module Blueprint
    class VariablesController
      attr_accessor :json, :variables

      # @params path
      def initialize(path)
        @json = JSON.parse(File.read(path))
        @variables = user_variables
      end

      # Gives Subutai.json user variables
      # returns json object
      def user_variables
        hash = {}

        user_variables = @json['user-variables']
        keys = user_variables.keys

        keys.each do |key|
          hash[key] = get_input(user_variables[key])
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

        arr
      end

      # Gets input variable
      # @params variable json object
      def get_input(variable_json)
        STDOUT.puts "\e[33m#{variable_json['description']}: (Ex: #{variable_json['default']})\e[0m"

        if variable_json['type'] == 'enum'
          STDOUT.puts "\e[33mEnter your container size (Ex: #{variable_json['default']}):\e[0m"
          validations = variable_json['validation'].split(',')
          validations.each_with_index do |validation, index|
            STDOUT.puts "   \e[33m #{index}. #{validation}:\e[0m"
          end
          STDOUT.puts "\e[33mChoose your container size between ( 0 to n)\e[0m"
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