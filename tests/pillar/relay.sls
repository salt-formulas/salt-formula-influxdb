influxdb:
  relay:
    enabled: true
    telemetry:
      enabled: true
      bind:
        address: 127.0.0.1
        port: 9196
    listen:
      http_backend:
        type: http
        bind:
          address: 127.0.0.1
          port: 9096
        output:
          server1:
            location: http://server1:8086/write
            timeout: 20s
            buffer_size_mb: 512
            max_batch_kb: 1024
            max_delay_interval: 30s
          server2:
            location: http://server2:8086/write
      udp_backend:
        type: udp
        bind:
          address: 127.0.0.1
          port: 9196
        output:
          server1:
            location: http://server1:8086/write
            mtu: 1500
          server2:
            location: http://server2:8086/write
