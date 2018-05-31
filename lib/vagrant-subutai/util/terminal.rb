module VagrantSubutai
  module Util
    class Terminal
      def self.execute_cmd(*command)
        system(*command)
      end
    end
  end
end