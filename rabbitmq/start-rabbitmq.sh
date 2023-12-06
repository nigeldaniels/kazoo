#!/bin/bash

# Start RabbitMQ in the background
/usr/lib/rabbitmq/bin/rabbitmq-server -detached

# Wait for a short period to allow RabbitMQ to start and log files to be created
sleep 10

# Tail the RabbitMQ log files
tail -f /var/log/rabbitmq/*.log