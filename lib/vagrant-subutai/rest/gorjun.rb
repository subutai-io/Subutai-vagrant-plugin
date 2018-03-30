require 'net/https'
require 'uri'
require 'json'
require_relative '../../vagrant-subutai'

module VagrantSubutai
  module Rest
    class Gorjun
      def self.template_id(name, owner)
        uri = URI.parse("#{url}?name=#{name}&owner=#{owner}")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri)
        response = https.request(request)

        case response
          when Net::HTTPOK
            response = JSON.parse(response.body)
            response[0]['id']
          else
            Put.error "Try again! #{response.body} template name #{name}, owner #{owner}"
        end
      end

      def self.url
        env = SubutaiConfig.get(:SUBUTAI_ENV)
        env = env.to_s

        if env == VagrantSubutai::Configs::Environment::PROD
          return VagrantSubutai::Configs::Gorjun::INFO_PROD
        elsif env == VagrantSubutai::Configs::Environment::MASTER
          return VagrantSubutai::Configs::Gorjun::INFO_MASTER
        elsif env == VagrantSubutai::Configs::Environment::DEV
          return VagrantSubutai::Configs::Gorjun::INFO_DEV
        end
      end
    end
  end
end
