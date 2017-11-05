job "tshoot2" { 
  datacenters = ["dc1"] 
  type = "service" 

  group "tshoot" { 
    count = 1 

    task "tshoot" { 
      driver = "docker" 
      env {
        HOST_IP = "${attr.unique.network.ip-address}"
      }

      config { 
        image = "powisj/tshoot:latest" 
        force_pull = true
        port_map { 
          http = 80 
        }
	dns_search_domains = ["service.consul"]
        dns_servers = ["${HOST_IP}", "8.8.8.8", "4.2.2.2"]
      }

      resources { 
        cpu    = 500 # 500 MHz 
        memory = 256 # 256MB 
        network { mbits = 10 port "http" {} } 
      } 

      service {
        name = "tshoot2"
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
