# Vagrant Subutai Plugin

Vagrant Subutai Plugin - executes Subutai scripts in target hosts

## Installation

    $ vagrant plugin install vagrant-subutai

## Usage
```
Usage: vagrant subutai command [command options] [arguments...]

COMMANDS:
    help [<command>...]
      Show help.

    daemon
      Run subutai agent daemon

    list containers
      List containers

    list templates
      List templates

    list all
      List all

    list info
      List containers info

    attach <name> [<command>]
      Attach to Subutai container

    clone [<flags>] <template> <container>
      Create Subutai container

    cleanup <vlan>
      Cleanup environment

    prune
      Prune templates with no child containers

    destroy <name>
      Destroy Subutai container/template

    export --token=TOKEN [<flags>] <container>
      Export container as a template

    import [<flags>] <template>
      Import Subutai template

    info id [<container>]
      host/container id

    info system
      Host info

    info os
      Host os

    info ipaddr
      Host ip address

    info ports
      Host used ports

    info du <container>
      Container disk usage

    info qu <container>
      Container quota usage

    hostname rh <hostname>
      Set RH hostname

    hostname con <container> <hostname>
      Set container hostname

    map add --protocol=PROTOCOL --external port=EXTERNAL PORT --internal server=INTERNAL SERVER [<flags>]
      Add port mapping

    map rm --protocol=PROTOCOL --external port=EXTERNAL PORT [<flags>]
      Remove port mapping

    map list [<flags>]
      List mapped ports

    metrics --start=START --end=END <name>
      Print host/container metrics

    proxy create --protocol=PROTOCOL --port=PORT --tag=TAG [<flags>]
      Create proxy

    proxy list [<flags>]
      List proxies

    proxy remove --tag=TAG
      Remove proxy

    proxy server add --tag=TAG --server=SERVER
      Add proxied server

    proxy server remove --tag=TAG --server=SERVER
      Remove proxied server

    proxy server list --tag=TAG
      List servers for proxy

    quota get --resource=RESOURCE --container=CONTAINER
      Print container resource quota

    quota set --resource=RESOURCE --container=CONTAINER <limit>
      Set container resource quota

    start <name(s)>...
      Start Subutai container

    stop <name(s)>...
      Stop Subutai container

    restart <name(s)>...
      Restart Subutai container

    update [<flags>] <component>
      Update peer components

    tunnel add [<flags>] <socket> [<ttl>]
      Create ssh tunnel

    tunnel del <socket>
      Delete ssh tunnel

    tunnel list
      List ssh tunnels

    vxlan add --remoteip=REMOTEIP --vni=VNI --vlan=VLAN <name>
      Add vxlan tunnel

    vxlan del <name>
      Delete vxlan tunnel

    vxlan list
      List vxlan tunnels

    batch <commands>
      Execute a batch of commands

    register
      Register Subutai PeerOS to Bazaar

    unregister
      Unregister Subutai PeerOS from Bazaar

    fingerprint
      Shows fingerprint Subutai Console

    open
      Open the Subutai PeerOS in browser

    blueprint
      Run blueprint provisioning


GLOBAL OPTIONS:
    -h, --help
      Show help
```

