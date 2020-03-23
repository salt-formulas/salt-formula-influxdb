{%- from "influxdb/map.jinja" import client with context %}

{%- if client.get('enabled') %}
{# CUSTOM QUERIES, intended to be called by salt_id #}

{%- set mconf = pillar.salt.minion.get('config', {}).get('influxdb') %}

{%- for db_name,db in client.get('database', {}).items() %}
{%- set db_name = db.get('name', db_name) %}
{%- for qr_name,qr in db.get('query', {}).items() %}

{%- if qr is string %}
{%- set query = { 'query': qr } %}
{%- endif %}

influxdb_query_{{ db_name }}_{{ qr_name }}:
  module.run:
    influxdb.query:
      - database: {{ db_name }}
      - query: {{ query }}
      - host: {{ mconf.host }}
      - port: {{ mconf.port }}
      {%- if qr.user is defined OR mconf.password is defined %}
      - user: {{ qr.get('user', mconf.user) }}
      {%- endif %}
      {%- if qr.password is defined OR mconf.password is defined %}
      - password: {{ qr.get('password', mconf.password) }}
      {%- endif %}
{%- endfor %}
{%- endfor %}

