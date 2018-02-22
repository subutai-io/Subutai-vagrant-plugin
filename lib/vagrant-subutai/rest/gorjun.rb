require 'net/https'
require 'uri'
require 'json'
require_relative '../../vagrant-subutai'

module VagrantSubutai
  module Rest
    class Gorjun
      def self.template_id(name, owner)
        uri = URI.parse("#{VagrantSubutai::Configs::Gorjun::INFO_MASTER}?name=#{name}&owner=#{owner}")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        response = https.request(request)

        case response
          when Net::HTTPOK
            response = JSON.parse(response.body)
            response[0]['id']
          else
            raise "Try again! #{response.body}"
        end
      end

      def self.url
        env = SubutaiConfig.get(:SUBUTAI_ENV)

        if env == VagrantSubutai::Configs::Environment::PROD
          return VagrantSubutai::Configs::Gorjun::INFO_PROD
        elsif env == VagrantSubutai::Configs::Environment::MASTER
          return VagrantSubutai::Configs::Gorjun::INFO_MASTER
        elsif env == VagrantSubutai::Configs::Environment::SYSNET
          return VagrantSubutai::Configs::Gorjun::INFO_SYSNET
        elsif env == VagrantSubutai::Configs::Environment::DEV
          return VagrantSubutai::Configs::Gorjun::INFO_DEV
        end
      end
    end
  end
end