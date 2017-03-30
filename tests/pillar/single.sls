influxdb:
  server:
    enabled: true
linux:
  system:
    enabled: true
    repo:
      docker:
        source: 'deb https://repos.influxdata.com/ubuntu {{ grains.get('oscodename') }} stable'
        key_url: https://repos.influxdata.com/influxdb.key
        file: /etc/apt/sources.list
