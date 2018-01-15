# SubutaiCli

Vagrant Subutai CLI - executes Subutai scripts in target hosts

## Installation

    $ vagrant plugin install subutai_cli

## Configuration / Usage

Required to add peer IP address to Vagrantfile. Here is an Example Vagrantfile

```
Vagrant.configure("2") do |config|
  config.subutai_console.url = "https://YOUR_LOCAL_PEER_IP:YOUR_LOCAL_PEER_PORT"
end
```

## Usage
        Usage: vagrant subutai [options]
        -l, --log            - show snap logs
        -u, --update NAME    - update Subutai rh or management
        -r, --register       - register Subutai peer to hub
        -h, --help           - help 

        Example usage : vagrant subutai -r



