# swarm-ssh-gateway

You may want to access some services in your docker swarm from your local machine over an SSH tunnel (RabbitMQ Admin console for one). But swarm services are not exposed in host mode by default and you cannot access them even when you are logged in.

But we can create a trick, we will add an SSH gateway to the swarm network and create tunnels to access the ports. The beauty is, that it would solve service name resolution for free.

## Gateway part (your ops role)

### Open gateway

To open a gatweay run container by using the command bellow:

> [!CAUTION]
> Please watch the mount point! It binds a special `authorized_keys` file and you have to create it first! This is the place where you grant users right to use the gateway.

```sh
docker run -d --rm \
  --name swarm-ssh-gateway-STACK_NAME \
  --network STACK_NETWORK \
  --volume /root/.ssh/authorized_keys.swarm-ssh-gateway:/root/.ssh/authorized_keys \
  -p 127.0.0.1:8022:22 brablc/swarm-ssh-gateway
```

### Close gateway

```sh
docker exec swarm-ssh-gateway-STACK_NAME kill 1
```

> [!NOTE]
> Unfortunatelly the gateway cannot be added as swarm service, because we would need to publish port in host mode i.e. on all network interfaces and create a security risk.


## Tunneling part (your dev role)

### Configure ssh config

On your personal computer modify your `~/.ssh/config`:

```
Host jump.example.com
    HostName mng.example.com
    User dev1
    ForwardAgent yes

Host swarm-ssh-gateway-STACK_NAME
    HostName 127.0.0.1
    User root
    Port 8022
    ProxyJump jump.example.com
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    RequestTTY no
    ExitOnForwardFailure yes
    # These are names of your services from your stack - hostname reesolution works automatically
    LocalForward 127.0.0.1:15672 rabbitmq:15672
    LocalForward 127.0.0.1:5432 postgres:5432
    LocalForward 127.0.0.1:8123 clickhouse1:8123
    LocalForward 127.0.0.1:9000 clickhouse1:9000
```

### Open tunnel

Now you can open the tunnel:

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
