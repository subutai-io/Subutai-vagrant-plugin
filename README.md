# SubutaiCli

Vagrant Subutai CLI - executes Subutai scripts in target hosts

## Installation

    $ vagrant plugin install subutai_cli

## Configuration / Usage

Required to add Subutai Peer IP address to Vagrantfile. Here is an Example Vagrantfile

```
Vagrant.configure("2") do |config|
  config.subutai_console.url = "https://YOUR_LOCAL_PEER_IP:YOUR_LOCAL_PEER_PORT"
end
```

## Usage
```
Usage: vagrant subutai [global options] command [command options] [arguments...]

COMMANDS:
       attach             attach to Subutai container
       backup             backup Subutai container
       batch              batch commands execution
       checkpoint         checkpoint/restore in user space
       clone              clone Subutai container
       cleanup            clean Subutai environment
       config             edit container config
       daemon             start Subutai agent
       demote             demote Subutai container
       destroy            destroy Subutai container
       export             export Subutai container
       import             import Subutai template
       info               information about host system
       hostname           Set hostname of container or host
       list               list Subutai container
       log                print application logs
       map                Subutai port mapping
       metrics            list Subutai container
       migrate            migrate Subutai container
       p2p                P2P network operations
       promote            promote Subutai container
       proxy              Subutai reverse proxy
       quota              set quotas for Subutai container
       rename             rename Subutai container
       restore            restore Subutai container
       stats              statistics from host
       start              start Subutai container
       stop               stop Subutai container
       tunnel             SSH tunnel management
       update             update Subutai management, container or Resource host
       vxlan              VXLAN tunnels operation
       register           register Subutai Peer to Hub
       add                add new RH to Subutai Peer
       fingerprint        shows fingerprint Subutai Console

GLOBAL OPTIONS:
       --help, -h     show help
```

