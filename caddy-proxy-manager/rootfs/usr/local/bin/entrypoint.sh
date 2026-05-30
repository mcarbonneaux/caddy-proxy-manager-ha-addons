#!/bin/bash
set -e

# Run init-config synchronously before supervisord starts
/usr/local/bin/init-config.sh

# Hand off to supervisord for caddy + cpm
exec /usr/bin/supervisord -c /etc/supervisord.conf
