# swarm-ssh-gateway

You may want to access some services in your docker swarm from your local machine over an SSH tunnel (RabbitMQ Admin console for one). But swarm services are not exposed in host mode by default and you cannot access them even when you ssh to them.

The solution is to add SSH gateway (aka bastion) to the swarm network and build a tunnel from you local machine to gateway and from gateway to your swarm services. The beauty of this solution is, that it solves service hostname name resolution for free.

## Gateway part

This must be done by the priviliged person on one of your docker swarm nodes. I.e. your operator role. It can actually be any node that has ssh access from ouside, but using manager node is preferred.

### Open gateway

Run the command to create a gatweay container:

> [!IMPORTANT]
> Please watch the mount point! It binds a special `authorized_keys` file and you have to create it first! This is the place where you grant users right to use the gateway.

```sh
docker run --detach \
  --name swarm-ssh-gateway-STACK_NAME \
  --restart=always \
  --network STACK_NETWORK \
  --volume /root/.ssh/authorized_keys.swarm-ssh-gateway:/root/.ssh/authorized_keys \
  -p 127.0.0.1:8022:22 brablc/swarm-ssh-gateway
```

### Close gateway

```sh
# Legit
docker stop swarm-ssh-gateway-STACK_NAME

# Or fast
docker exec swarm-ssh-gateway-STACK_NAME kill 1
```

## Tunneling part

This is intended for team members, that need to access the services from swarm on their local machines. I.e. you developer role.

### Configure ssh config

On your personal computer modify your `~/.ssh/config`:

```ssh
Host manager.example.com
    HostName manager.example.com
    User dev1
    ForwardAgent yes

Host swarm-ssh-gateway-STACK_NAME
    HostName 127.0.0.1
    User root
    Port 8022
    ProxyJump manager.example.com
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    RequestTTY no
    ExitOnForwardFailure yes
    # These are the names of your services from your stack - hostname reesolution works automatically
    LocalForward 127.0.0.1:15672 rabbitmq:15672
    LocalForward 127.0.0.1:5432 postgres:5432
    LocalForward 127.0.0.1:8123 clickhouse1:8123
    LocalForward 127.0.0.1:9000 clickhouse1:9000
```

### Open tunnel

Now you can open the tunnel on your local machine:

```sh
ssh -N swarm-ssh-gateway-STACK_NAME &
```

### Use tunnel

```sh
nmap -p 15672 127.0.0.1
```

### Close tunnel

When you are done, you can stop the tunnel:

```sh
$ jobs
[1]+  Running                 ssh -N swarm-ssh-gateway-STACK_NAME &
 ~
$ kill %1
[1]+  Done                    ssh -N swarm-ssh-gateway-STACK_NAME

# Or

$ fg
ssh -N swarm-ssh-gateway-STACK_NAME
^C
```
