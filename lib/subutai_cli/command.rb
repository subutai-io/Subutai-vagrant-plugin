module SubutaiCli
  class Command < Vagrant.plugin("2", "command")
    def execute
      @command = "subutai"
      options = OpenStruct.new
      options.library = ""
      options.inplace = false
      options.encoding = "utf8"
      options.transfer_type = :auto
      options.verbose = false
      options.list= ""

      opt_parser = OptionParser.new do |opts|

        opts.banner = "Usage: vagrant subutai [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-c", "--command COMMAND", "Provide Subutai command to execute") do |lib|
          options.library.concat(lib)
        end

        opts.on("-l", "--list ADDITIONAL ARGS", "Provide additional comma seperated args ") do |list|
          options.list = list
        end

        opts.on("-h", "--help", "HELP") do
          puts opts
          exit
        end

      end
      parse_options(opt_parser)

      @command = @command.
          concat(" ").
          concat(options.library)

      if options.list.length > 0
        @command = @command.concat(" ").concat(options.list.gsub!(',', ' '))
      end

      machine = @env.machine(:default, :virtualbox)
      if machine.state.id != :running
        @env.ui.error("Machine must be running.")
        return 1
      end
      puts @command
      machine.communicate.execute(@command) do |type, data|
        @env.ui.info(data)
      end
      return 0
    end
  end
end