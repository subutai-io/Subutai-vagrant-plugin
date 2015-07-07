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
      options.hosts=""

      opt_parser = OptionParser.new do |opts|

        opts.banner = "Usage: vagrant subutai [options]

        clone           - clones an instance container from a template
        config          - adds or deletes a config path on a container
        demote          - demotes a template back to an instance container
        destroy         - destroys a template or instance container
        export          - export a template
        import          - import a template
        list            - lists templates and instance containers
        master_create   - creates a new master from scratch
        master_destroy  - destroys the master template
        master_export   - exports the master template
        master_import   - imports master template
        promote         - promotes an instance container into a template
        register        - registers the template with the site registry
        rename          - renames an instance container
        setup           - setups up the host

        Example usage : vagrant subutai -c clone -l master,subtemplate
"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-c", "--command COMMAND", "Provide Subutai command to execute") do |lib|
          options.library.concat(lib)
        end

        opts.on("-l", "--list ADDITIONAL ARGS", "Provide additional comma separated args ") do |list|
          options.list = list
        end

        opts.on("-t", "--target TARGET HOSTS", "Provide target host(s) in comma separated list for multiple targets") do |hosts|
          options.hosts = hosts
        end

        opts.on("-h", "--help", "PRINT USAGE") do
          puts opts
          exit
        end

      end
      parse_options(opt_parser)

      #get the command
      if options.library.length >0
        @command = @command.
            concat(" ").
            concat(options.library)
      else
        puts opt_parser
        return 0
      end


      #parse if any additional args are provided
      if options.list.length > 0
        @command = @command.concat(" ").concat(options.list.gsub!(',', ' '))
      else
        puts opt_parser
        return 0
      end

      #parse target hosts
      if options.hosts.length > 0

        targets = options.hosts.gsub!(',', ' ')

        with_target_vms(targets) do |machine|

          if machine.state.id != :running
            @env.ui.error("Machine must be running.")
          end

          machine.communicate.execute(@command) do |type, data|
            @env.ui.info(data)
          end
        end
      end

      return 0
    end
  end
end