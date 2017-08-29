{%- from "influxdb/map.jinja" import relay with context %}
{%- if relay.get('enabled') %}

influxdb_relay_packages:
  pkg.installed:
  - names: {{ relay.pkgs }}

influxdb_relay_config:
  file.managed:
  - name: //etc/influxdb-relay/influxdb-relay.conf
  - source: salt://influxdb/files/influxdb-relay.conf
  - template: jinja
  - require:
    - pkg: influxdb_relay_packages

influxdb_relay_service:
  service.running:
  - enable: true
  - name: {{ relay.service }}
{%- if grains.get('noservices') %}
  - onlyif: /bin/false
{%- endif %}
  - watch:
    - file: influxdb_relay_config

{%- endif %}
