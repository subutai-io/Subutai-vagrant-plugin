require '../vagrant-subutai'
require 'json'

module VagrantSubutai
  class BlueprintController
    attr_accessor :json

    # @params path
    def initialize(path)
      @json = JSON.parse(File.open(path))
    end

    # Gives Subutai.json user variables
    # returns json object
    def user_variables
      @json['user-variables']
    end

    # Gets input variable
    # @params variable json object
    def get_input(variable_json)
      STDOUT.puts "\e[33m#{variable_json['description']}:\e[0m"

      if variable_json['type'] == 'enum'
        STDOUT.puts "Enter your container size:"
        validations = variable_json['validation']
        validations.split(',').each do |validation, index|
          STDOUT.puts "   \e[33m #{index}. #{validation}:\e[0m"
        end
        STDOUT.puts "Choose your container size between ( 0 to n)"
        input = STDIN.gets.strip.to_i
        validations[input]
      else
        STDIN.gets.strip
      end
    end

    # Validate variable
    # @params var, type, validation
    def validate(var, variable_json)
      if var =~ variable_json['validation']
        true
      else
        false
      end
    end

=begin
{
        "environmentName": {
            "description": "Enter the environment name",
            "type": "string",
            "default": "Ruby on Rails",
            "validation": "[a-zA-Z0-9]+"
          },
          "domainName": {
            "description": "Enter the application domain name",
            "type": "domain",
            "default": "change.the.domain",
            "validation": "[a-zA-Z0-9]+"
          },
          "webContainerName": {
            "description": "Enter the container's hostname",
            "type": "string",
            "default": "ruby-on-rails",
            "validation": "[a-zA-Z0-9]+"
          },
          "webContainerSize": {
            "description": "Set the container size to SMALL, MEDIUM, LARGE or HUGE",
            "type": "enum",
            "default": "SMALL",
            "validation": "SMALL,MEDIUM,LARGE,HUGE"
          }
}
=end
  end
end