influxdb:
  server:
    enabled: true
    data:
      dir: /opt/influxdb/data
      wal_dir: /opt/influxdb/wal
    meta:
      dir: /opt/influxdb/meta
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
