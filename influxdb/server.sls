{%- from "influxdb/map.jinja" import server with context %}
{%- if server.enabled %}

influxdb_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

influxdb_config:
  file.managed:
  - name: /etc/influxdb/influxdb.conf
  - source: salt://influxdb/files/influxdb.conf
  - template: jinja
  - require:
    - pkg: influxdb_packages

influxdb_default:
  file.managed:
  - name: /etc/default/influxdb
  - source: salt://influxdb/files/default
  - template: jinja
  - require:
    - pkg: influxdb_packages

influxdb_service:
  service.running:
  - enable: true
  - name: {{ server.service }}
  - watch:
    - file: influxdb_config
    - file: influxdb_default

{%- endif %}
