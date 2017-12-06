linux:
  system:
    enabled: true
    repo:
      linux_influxdata:
        source: "deb http://repos-backend.influxdata.com/ubuntu {{ grains.get('oscodename') }} stable"
        architectures: amd64
        key_url: "http://repos-backend.influxdata.com/influxdb.key"
