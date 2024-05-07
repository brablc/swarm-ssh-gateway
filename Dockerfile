FROM alpine:latest

RUN apk add --no-cache openssh \
    && mkdir /root/.ssh \
    && sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config \
    && ssh-keygen -A

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
