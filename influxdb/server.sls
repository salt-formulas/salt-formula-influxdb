{%- from "influxdb/map.jinja" import server with context %}

{%- if server.enabled %}

{%- if not server.container_mode %}
influxdb_packages:
  pkg.installed:
  - names: {{ server.pkgs }}
{%- endif %}

{{ server.prefix_dir }}/etc/influxdb:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

influxdb_config:
  file.managed:
  - name: {{ server.prefix_dir }}/etc/influxdb/influxdb.conf
  - source: salt://influxdb/files/influxdb.conf
  - template: jinja
{%- if not server.container_mode %}
  - require:
    - pkg: influxdb_packages
{%- endif %}

{%- if not server.container_mode %}
influxdb_default:
  file.managed:
  - name: /etc/default/influxdb
  - source: salt://influxdb/files/default
  - template: jinja
  - require:
    - pkg: influxdb_packages
{%- endif %}

influxdb_service:
  service.running:
  - enable: true
  - name: {{ server.service }}
  # This delay is needed before being able to send data to server to create
  # users and databases.
  - init_delay: 5
{%- if grains.get('noservices') or server.container_mode %}
  - onlyif: /bin/false
{%- endif %}
  - watch:
    - file: influxdb_config
{%- if not server.container_mode %}
    - file: influxdb_default
{%- endif %}

{% set url_for_query = "http://{}:{}/query".format(server.http.bind.address, server.http.bind.port) %}
{% set admin_created = false %}

{%- if not server.container_mode and server.admin.get('user', {}).get('enabled', False) %}
  {% set query_create_admin = "--data-urlencode \"q=CREATE USER {} WITH PASSWORD '{}' WITH ALL PRIVILEGES\"".format(server.admin.user.name, server.admin.user.password) %}
  {% set admin_url = "http://{}:{}/query?u={}&p={}".format(server.http.bind.address, server.http.bind.port, server.admin.user.name, server.admin.user.password) %}
influxdb_create_admin:
  cmd.run:
  - name: curl -f -S -POST "{{ url_for_query }}" {{ query_create_admin }} || curl -f -S -POST "{{ admin_url }}" {{ query_create_admin }}
  - require:
    - service: influxdb_service
  {% set url_for_query = admin_url %}
  {% set admin_created = true %}
{%- endif %}

# An admin must exist before creating others users
{%- if admin_created %}
  {%- for user_name, user in server.get('user', {}).iteritems() %}
    {%- if user.get('enabled', False) %}
      {%- if user.get('admin', False) %}
        {% set query_create_user = "--data-urlencode \"q=CREATE USER {} WITH PASSWORD '{}' WITH ALL PRIVILEGES\"".format(user.name, user.password) %}
      {%- else %}
        {% set query_create_user = "--data-urlencode \"q=CREATE USER {} WITH PASSWORD '{}'\"".format(user.name, user.password) %}
      {%- endif %}
influxdb_create_user_{{user.name}}:
  cmd.run:
    - name: curl -f -S -POST "{{ url_for_query }}" {{ query_create_user }}
    - require:
      - cmd: influxdb_create_admin
    # TODO: manage user deletion
    {%- endif %}
  {%- endfor %}
{%- endif %}

{%- for db_name, db in server.get('database', {}).iteritems() %}
  {%- if db.get('enabled', False) %}
    {% set query_create_db = "--data-urlencode \"q=CREATE DATABASE {}\"".format(db.name) %}
influxdb_create_db_{{db.name}}:
  cmd.run:
    - name: curl -f -S -POST "{{ url_for_query }}" {{ query_create_db }}
    {%- if admin_created %}
    - require:
      - cmd: influxdb_create_admin
    {%- endif %}
  # TODO: manage database deletion

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

    - name: curl -s -S -POST "{{ url_for_query }}" --data-urlencode "q=CREATE {{ query_retention_policy }}"|grep -v "policy already exists" || curl -s -S -POST "{{ url_for_query }}" --data-urlencode "q=ALTER {{ query_retention_policy }}"
    - require:
      - cmd: influxdb_create_db_{{db.name}}
    {%- endfor %}
  {%- endif %}
{%- endfor %}

# An admin must exist to manage grants, otherwise there is no user.
{%- if admin_created %}
{%- for grant_name, grant in server.get('grant', {}).iteritems() %}
  {%- if grant.get('enabled', False) %}
    {% set query_grant_user_access = "--data-urlencode \"q=GRANT {} ON {} TO {}\"".format(grant.privilege, grant.database, grant.user) %}
influxdb_grant_{{grant_name}}:
  cmd.run:
    - name: curl -f -S -POST "{{ url_for_query }}" {{ query_grant_user_access }}
    - require:
      - cmd: influxdb_create_db_{{grant.database}}
      - cmd: influxdb_create_user_{{grant.user}}
      - cmd: influxdb_create_admin
    # TODO: manage grant deletion (if needed)
  {%- endif %}
{%- endfor %}
{%- endif %}

{%- endif %}
