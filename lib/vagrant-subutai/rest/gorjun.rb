require 'net/https'
require 'uri'
require 'json'
require_relative '../../vagrant-subutai'

module VagrantSubutai
  module Rest
    class Gorjun
      def self.template_id(name, owner)
        puts name
        puts owner
        uri = URI.parse("#{Configs::Gorjun::INFO}?name=#{name}&owner=#{owner}")
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
    end
  end
end