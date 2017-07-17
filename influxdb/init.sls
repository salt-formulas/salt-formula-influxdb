{% if pillar.influxdb.server is defined %}
include:
- influxdb.server
{% endif %}
