
========
InfluxDB
========

InfluxData is based on the TICK stack, the first open source platform for managing IoT time-series data at scale.

Sample pillars
==============

Single-node influxdb, enabled http frontend and admin web interface:

.. code-block:: yaml

    influxdb:
      server:
        enabled: true
        http:
          enabled: true
          bind:
            address: 0.0.0.0
            port: 8086
        admin:
          enabled: true
          bind:
            address: 0.0.0.0
            port: 8083

Single-node influxdb, SSL for http frontend:

.. code-block:: yaml

    influxdb:
      server:
        enabled: true
        http:
          bind:
            ssl:
              enabled: true
              key_file: /etc/influxdb/ssl/key.pem
              cert_file: /etc/influxdb/ssl/cert.pem

InfluxDB relay:

.. code-block:: yaml

    influxdb:
      server:
        enabled: true
        http:
          enabled: true
          output:
            idb01:
              location: http://idb01.local:8086/write
              timeout: 10
            idb02:
              location: http://idb02.local:8086/write
              timeout: 10
        udp:
          enabled: true
          output:
            idb01:
              location: idb01.local:9096
            idb02:
              location: idb02.local:9096

Deploy influxdb apt repository (using linux formula):

.. code-block:: yaml

    linux:
      system:
        os: ubuntu
        dist: xenial
      repo:
        influxdb:
          enabled: true
          source: 'deb https://repos.influxdata.com/${linux:system:os} ${linux:system:dist} stable'
          key_url: 'https://repos.influxdata.com/influxdb.key'

Read more
=========

* https://influxdata.com/time-series-platform/influxdb/
