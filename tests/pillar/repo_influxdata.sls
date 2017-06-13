linux:
  system:
    enabled: true
    repo:
      linux_influxdata:
        source: "deb https://repos.influxdata.com/ubuntu {{ grains.get('oscodename') }} stable"
        architectures: amd64
        key_url: "https://repos.influxdata.com/influxdb.key"
