{%- from "influxdb/map.jinja" import client with context %}

{%- if client.get('enabled') %}

{%- set curl_command = 'curl' %}
{%- if grains.get('noservices') %}
{%- set curl_command = 'true ' + curl_command %}
{%- endif %}

{%- set noauth_url = "{}://{}:{}/query".format(client.server.protocol, client.server.host, client.server.port) %}
{%- set auth_url = "{}?u={}&p={}".format(noauth_url, client.server.user, client.server.password) %}

{# Create the admin user (this is only required on the first run) #}
{% set create_admin_query = "--data-urlencode \"q=CREATE USER {} WITH PASSWORD '{}' WITH ALL PRIVILEGES\"".format(client.server.user, client.server.password) %}
influxdb_create_admin:
  cmd.run:
  - name: {{ curl_command }} -f -S -POST "{{ noauth_url }}" {{ create_admin_query }} || {{ curl_command }} -f -S -POST "{{ auth_url }}" {{ create_admin_query }}

{# Create the regular users #}
{%- for user_name, user in client.get('user', {}).iteritems() %}
  {%- if user.get('enabled', False) %}
      {%- if user.get('admin', False) %}
        {% set create_user_query = "--data-urlencode \"q=CREATE USER {} WITH PASSWORD '{}' WITH ALL PRIVILEGES\"".format(user.name, user.password) %}
      {%- else %}
        {% set create_user_query = "--data-urlencode \"q=CREATE USER {} WITH PASSWORD '{}'\"".format(user.name, user.password) %}
      {%- endif %}
influxdb_create_user_{{user.name}}:
  cmd.run:
    - name: {{ curl_command }} -f -S -POST "{{ auth_url }}" {{ create_user_query }}
    - require:
      - cmd: influxdb_create_admin
  {%- endif %}
{%- endfor %}

{# Create the databases #}
{%- for db_name, db in client.get('database', {}).iteritems() %}
  {%- if db.get('enabled', False) %}
    {% set create_db_query = "--data-urlencode \"q=CREATE DATABASE {}\"".format(db.name) %}
influxdb_create_db_{{ db.name }}:
  cmd.run:
    - name: {{ curl_command }} -f -S -POST "{{ auth_url }}" {{ create_db_query }}
    - require:
      - cmd: influxdb_create_admin

    {% for rp in db.get('retention_policy', []) %}
    {% set rp_name = rp.get('name', 'autogen') %}
    {% if rp.get('is_default') %}
      {% set is_default = 'DEFAULT' %}
    {% else %}
      {% set is_default = '' %}
    {% endif %}
    {% set duration = rp.get('duration', 'INF') %}
    {% set replication = rp.get('replication', '1') %}
    {% if rp.get('shard_duration') %}
      {% set shard_duration = 'SHARD DURATION {}'.format(rp.shard_duration) %}
    {% else %}
      {% set shard_duration = '' %}
    {% endif %}
    {% set query_retention_policy = 'RETENTION POLICY {} ON {} DURATION {} REPLICATION {} {} {}'.format(
        rp_name, db.name, duration, replication, shard_duration, is_default)
    %}
influxdb_retention_policy_{{db.name}}_{{ rp_name }}:
  cmd.run:
    - name: {{ curl_command }} -s -S -POST "{{ auth_url }}" --data-urlencode "q=CREATE {{ query_retention_policy }}"|grep -v "policy already exists" || {{ curl_command }} -s -S -POST "{{ auth_url }}" --data-urlencode "q=ALTER {{ query_retention_policy }}"
    - require:
      - cmd: influxdb_create_db_{{db.name}}
    {%- endfor %}
  {%- endif %}
{%- endfor %}

{%- for grant_name, grant in client.get('grant', {}).iteritems() %}
  {%- if grant.get('enabled', False) %}
    {% set query_grant_user_access = "--data-urlencode \"q=GRANT {} ON {} TO {}\"".format(grant.privilege, grant.database, grant.user) %}
influxdb_grant_{{ grant_name }}:
  cmd.run:
    - name: {{ curl_command }} -f -S -POST "{{ auth_url }}" {{ query_grant_user_access }}
    - require:
      - cmd: influxdb_create_db_{{ grant.database }}
      - cmd: influxdb_create_user_{{ grant.user }}
  {%- endif %}
{%- endfor %}


{# CONTINUOUS QUERIES #}
{%- for db_name, db in client.get('database', {}).iteritems() %}
  {%- set db_name = db.get('name', db_name) %}
  {%- for cq_name, cq in db.get('continuous_query', {}).iteritems() %}
    {%- set query_continuous_query = 'CONTINUOUS QUERY {} ON {} BEGIN {} END'.format(cq_name, db_name, cq ) %}
influxdb_continuous_query_{{db_name}}_{{ cq_name }}:
  cmd.run:
    - name: {{ curl_command }} -s -S -POST "{{ auth_url }}" --data-urlencode "q=CREATE {{ query_continuous_query }}"|grep -v "already exists" || {{ curl_command }} -s -S -POST "{{ auth_url }}" --data-urlencode "q=ALTER {{ query_continuous_query }}"
    - onlyif: {{ curl_command }} -s -S -POST "{{ auth_url }}" --data-urlencode "q=SHOW DATABASES" | grep {{ db_name }}

  {%- endfor %}
{%- endfor %}

{%- endif %}
