linux:
  system:
    enabled: true
    repo:
      linux_influxdata:
        source: "deb http://repos.influxdata.com/ubuntu {{ grains.get('oscodename') }} stable"
        architectures: amd64
        # key_url: "http://repos.influxdata.com/influxdb.key"
        # https repo not working - see https://github.com/influxdata/influxdb/issues/9199 for more info
