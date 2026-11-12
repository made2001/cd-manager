#!/bin/sh
echo "0 3 * * * sh /backup.sh" | crontab -
crond -f
