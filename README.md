# swarm-ssh-gateway

You may want to access some services in your docker swarm from your local machine over an SSH tunnel. But the services do not expose ports by default (they use the mesh network) and IT IS GOOD as they are not exposed on public IPs.

In order to create a tunnel, we need to add an SSH gateway to our stack network(s):

```sh
docker run -d --rm --name swarm-ssh-gateway-STACK_NAME \
  -v /root/.ssh/authorized_keys:/root/.ssh/authorized_keys \
  --network STACK_NETWORK \
  -p 127.0.0.1:8022:22 brablc/swarm-ssh-gateway
```

Unfortunatelly it cannot be added as swarm service, because we would need to publish ports in host mode, but swarm does not let us to choose on which interface.

On your personal computer you would modify `.ssh/config`:

```
Host mng.example.com
    HostName mng.example.com
    ForwardAgent yes

Host swarm-ssh-gateway-STACK_NAME
    HostName 127.0.0.1
    User root
    ProxyJump mng.example.com
    Port 8022
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    # These are names of your services from your stack
    # Resolution for automatically
    LocalForward 127.0.0.1:15672 rabbitmq:15672
    LocalForward 127.0.0.1:5432 postgres:5432
    LocalForward 127.0.0.1:8123 clickhouse1:8123
    LocalForward 127.0.0.1:9000 clickhouse1:9000
```

Now you can start the tunnel:

```sh
ssh -T swarm-ssh-gateway-STACK_NAME
```
