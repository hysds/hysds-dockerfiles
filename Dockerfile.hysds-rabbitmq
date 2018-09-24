FROM docker.io/rabbitmq:3-management

MAINTAINER Gerald Manipon (pymonger) "pymonger@gmail.com"
LABEL description="RabbitMQ image for HySDS"

# update configs
COPY configs/rabbitmq.config /etc/rabbitmq/rabbitmq.config
COPY configs/rabbitmq-server /etc/default/rabbitmq-server
