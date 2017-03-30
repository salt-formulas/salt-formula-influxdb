influxdb:
  server:
    enabled: true
    meta:
      enabled: true
      bind:
        address: 0.0.0.0
        port: 8088
        http_address: 0.0.0.0
        http_port: 8091
    admin:
      enabled: true
      bind:
        address: 0.0.0.0
        port: 8081
        http_address: 0.0.0.0
        http_port: 8083
    cluster:
      members:
        - host: idb01.local
          port: 8091
        - host: idb02.local
          port: 8091
        - host: idb03.local
          port: 8091
linux:
  system:
    enabled: true
    repo:
      docker:
        source: 'deb https://repos.influxdata.com/ubuntu {{ grains.get('oscodename') }} stable'
        key_url: https://repos.influxdata.com/influxdb.key
        file: /etc/apt/sources.list
