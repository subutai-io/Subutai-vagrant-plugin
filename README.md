# SubutaiCli

Vagrant Subutai CLI - executes Subutai scripts in target hosts

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'subutai_cli'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install subutai_cli

## Usage
        Usage: vagrant subutai [options]
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

        Example usage : vagrant subutai clone parent child




