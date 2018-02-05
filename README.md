# SubutaiCli

Vagrant Subutai CLI - executes Subutai scripts in target hosts

## Installation

    $ vagrant plugin install vagrant-subutai

## Usage
```
Usage: vagrant subutai command [command options] [arguments...]

COMMANDS:
       attach                  - attach to Subutai container
       backup                  - backup Subutai container
       batch                   - batch commands execution
       checkpoint              - checkpoint/restore in user space
       clone                   - clone Subutai container
       cleanup                 - clean Subutai environment
       config                  - edit container config
       daemon                  - start Subutai agent
       demote                  - demote Subutai container
       destroy                 - destroy Subutai container
       export                  - export Subutai container
       import                  - import Subutai template
       info                    - information about host system
       hostname                - Set hostname of container or host
       list                    - list Subutai container
       log                     - print application logs
       map                     - Subutai port mapping
       metrics                 - list Subutai container
       migrate                 - migrate Subutai container
       p2p                     - P2P network operations
       promote                 - promote Subutai container
       proxy                   - Subutai reverse proxy
       quota                   - set quotas for Subutai container
       rename                  - rename Subutai container
       restore                 - restore Subutai container
       stats                   - statistics from host
       start                   - start Subutai container
       stop                    - stop Subutai container
       tunnel                  - SSH tunnel management
       update                  - update Subutai management, container or Resource host
       vxlan                   - VXLAN tunnels operation
       register                - register Subutai Peer to Hub
       fingerprint             - shows fingerprint Subutai Console
       disk                    - manage Subutai disk

GLOBAL OPTIONS:
       -h, --help              - show help
```

