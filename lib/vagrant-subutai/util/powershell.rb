
module VagrantSubutai
  module Util
    class Powershell
      def self.execute(path, *args)
        command = [
            "powershell.exe",
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "&('#{path}')",
            *args
        ].flatten

        system(*command)
      end

      def self.cmd_execute(command)
        c = [
            executable,
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-Command",
            command
        ].flatten.compact

        system(*c)
      end
    end
  end
end

