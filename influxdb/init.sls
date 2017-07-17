{%- if pillar.influxdb is defined %}
include:
{%- if pillar.influxdb.server is defined %}
- influxdb.server
{%- endif %}
{%- if pillar.influxdb.client is defined %}
- influxdb.client
{%- endif %}
{%- endif %}
