require_relative '../../vagrant-subutai'
require 'json'

module VagrantSubutai
  module Blueprint
    class VariablesController
      attr_accessor :json

      # @params path
      def initialize(path)
        @json = JSON.parse(File.read(path))
      end

      # Gives Subutai.json user variables
      # returns json object
      def user_variables
        @json['user-variables']
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