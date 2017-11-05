### Reason for this project

Nomad and Consul while offering highly functional defaults, in the scope of docker the default -dev configuration
leaves much to be desired. Namely binding and advertising of 127.0.0.1 prevents a container from being able to
discover another without static port assignment, and [address_mode](https://www.nomadproject.io/docs/job-specification/service.html#address_mode)
being set to `driver`. 

With [address_mode](https://www.nomadproject.io/docs/job-specification/service.html#address_mode) set to `driver` your production environment must be one of the following:
- Utilizing an overlay network via IP-IP Tunnel similar to Ubuntu's [fan networking](https://wiki.ubuntu.com/FanNetworking).
- Each Docker node must have a unique IP Block for the bridge network on each host and a IPSEC Tunnel configured in a full mesh topography.

With [address_mode](https://www.nomadproject.io/docs/job-specification/service.html#address_mode) set to `auto` or `host` your production environment can be:
- Static or Dynamically allocated ports.
- May utilize conflicting subnets on each docker host.
- Does not require IPSEC Tunnels or Complex Overlay for Fan networks.
- If Dynamic port assignment is used, Some method of Service Discovery must be implemented within your application.

### Install Consul and Nomad

Download Consul Here: [https://www.consul.io/downloads.html](https://www.consul.io/downloads.html)

Download Nomad Here:  [https://www.nomadproject.io/downloads.html](https://www.nomadproject.io/downloads.html)

Unzip the files into a directory in your path, EX: `/usr/local/bin`

### Configuring for `address_mode = "driver"`

HELP WANTED - Not currently a priority as the administrative burden to accomplish this is significant for not much win.
Additionally it is not possible via the mechinism used below to dynamically discover the consul agents ip address for DNS setting.

Any assistance with fleshing out this design further would be appreciated.

##### Example Nomad job

```hcl
job "tshoot" { 
  datacenters = ["dc1"] 
  type = "service" 

  group "tshoot" { 
    count = 1 

    task "tshoot" { 
      driver = "docker" 
      env {
        HOST_IP = "${attr.unique.network.ip-address}" # IP address of the -network-interface flag
      }

      config { 
        image = "powisj/tshoot:latest" 
        force_pull = true
        port_map { 
          http = 80 
        }
	dns_search_domains = ["service.consul"]
        dns_servers = ["${attr.unique.network.ip-address}", "8.8.8.8", "4.2.2.2"]
      }

      resources { 
        cpu    = 500 # 500 MHz 
        memory = 256 # 256MB 
        network { mbits = 10 port "http" {} } 
      } 

      service {
        name = "tshoot"
        port = "http"
        check {
          type     = "http"
          port     = "http"
          path     = "/"
          interval = "5s"
          timeout  = "2s"
        }
      }
    } 
  } 
}
```

##### Starting Consul and Nomad

```bash
# Set target environment variables for advertisement
export MY_INTERFACE="en0" # Change this depending on your config
export MY_IP=`ifconfig $MY_INTERFACE | grep "inet " | awk '{print $2}'`

# Start Consul
sudo consul agent -dev -dns-port 53 -client=0.0.0.0 -advertise=$MY_IP -bind=0.0.0.0

# Start Nomad (In another shell, make sure to export the variables at the top)
nomad agent --dev -network-interface=$MY_INTERFACE
```

##### Running Nomad Jobs and Discovering Eachother

```bash
nomad run tshoot.nomad
nomad run tshoot2.nomad
tshoot=`docker ps | grep "tshoot-" | head -n 1 | awk '{print $1}'`
docker exec -it $tshoot /bin/bash

# In the tshoot container
ping -c 2 tshoot 
ping -c 2 tshoot2

# Using DNS SRV lookup for container IP and Port
dig tshoot2.service.consul. SRV

# Using HTTP consul interface to discover tshoot2 service ip
curl http://${HOST_IP}:8500/v1/catalog/service/tshoot
```

##### Example output of service discovery

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                      NAMES
e4b7080c4b03        6f112162828f        "nginx -g 'daemon ..."   18 minutes ago      Up 18 minutes       192.168.0.211:20187->80/tcp, 192.168.0.211:20187->80/udp   tshoot-8b6dcced-91ad-a95a-932c-0db671d921f6
5e2b24d5c0a8        6f112162828f        "nginx -g 'daemon ..."   18 minutes ago      Up 18 minutes       192.168.0.211:20754->80/tcp, 192.168.0.211:20754->80/udp   tshoot-50257b0a-1b99-5a57-8c44-5026e2725b30
$ docker exec -it e4b7080c4b03 /bin/bash
root@e4b7080c4b03:/# dig +short consul.service.consul.
192.168.0.211
root@e4b7080c4b03:/# dig +short tshoot2.service.consul. SRV
1 1 20187 Omni.local.node.dc1.consul.
root@e4b7080c4b03:/# curl --head http://Omni.local.node.dc1.consul:20187
HTTP/1.1 200 OK
...
root@e4b7080c4b03:/# curl --head http://$(dig +short tshoot2.service.consul. SRV | awk '{print $4":"$3}' | sed 's/.:/:/g')/
HTTP/1.1 200 OK
...
```
