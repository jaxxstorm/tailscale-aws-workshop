# Configure as a peer relay

We'll need to use the SSH key we configured when we created the device, and login to the instance that has a public IP address (that we created manually). We can either use the public address we assigned, or alternatively use the tailscale address to login:

```bash
sh ec2-user@ip-172-16-4-190
The authenticity of host 'ip-172-16-4-190 (100.120.183.126)' can't be established.
ED25519 key fingerprint is SHA256:wPpWvAHQv+QYHJ2qWd4jiiuNQhCwAUI2uJlYu2GPvis.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:438: 18.237.116.163
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ip-172-16-4-190' (ED25519) to the list of known hosts.
```

?> Notice how SSH is telling us we previously logged into this device with our public key? We're now connecting over the encrypted Tailscale tunnel!

## Configure the client to be a peer relay

We can use the `tailscale set` command to configure this device as a peer relay:

```bash
[ec2-user@ip-172-16-4-190 ~]$ sudo -s
[root@ip-172-16-4-190 ec2-user]# tailscale set --relay-server-port=12345
[root@ip-172-16-4-190 ec2-user]# 
```

You can choose any _unused_ port, `12345` is just easy to remember!

## Configure a peer relay policy

We now need to update our Tailscale ACL to configure which devices this peer relay can be used to reach. We'll use the JSON editor to do this:

![](img/connectivity-testing/json-editor.png)

If you scroll down, you should see a top-level grant that is very permissive:

```
"grants": [
    // Allow all connections.
    // Comment this section out if you want to define specific restrictions.
    {
        "src": ["*"],
        "dst": ["*"],
        "ip":  ["*"],
    },

    // Allow users in "group:example" to access "tag:example", but only from
    // devices that are running macOS and have enabled Tailscale client auto-updating.
    // {"src": ["group:example"], "dst": ["tag:example"], "ip": ["*"], "srcPosture":["posture:autoUpdateMac"]},
],
```

We'll add a specific grant for peer relays to this array:

```
{
    "src": ["tag:subnet-router"], // Devices that can be accessed through the peer relay
    "dst": ["100.120.183.126"], // Devices functioning as peer relays for the src devices
    "app": {
        "tailscale.com/cap/relay": [], 
    },
},
```

You'll need to use the IP address you got for your device in the `dst` field. Comments are allowed in Tailscale's [HuJSON](https://github.com/tailscale/hujson) format.

Now, we have one final step to perform - we need to open the port we configured in the AWS security group. Head back to our security group page and add the UDP port we configured as a peer relay:

![](img/connectivity-testing/peer-relay-port-sg.png)

## Connectivity Retest

Now, let's retest our connectivity:

```bash
tailscale ping tailscale-ec2-client-1
pong from tailscale-ec2-client-1 (100.116.238.16) via DERP(sea) in 27ms
pong from tailscale-ec2-client-1 (100.116.238.16) via DERP(sea) in 34ms
pong from tailscale-ec2-client-1 (100.116.238.16) via DERP(sea) in 28ms
pong from tailscale-ec2-client-1 (100.116.238.16) via peer-relay(18.237.116.163:12345:vni:1) in 33ms
pong from tailscale-ec2-client-1 (100.116.238.16) via peer-relay(18.237.116.163:12345:vni:1) in 31ms
pong from tailscale-ec2-client-1 (100.116.238.16) via peer-relay(18.237.116.163:12345:vni:1) in 27ms
pong from tailscale-ec2-client-1 (100.116.238.16) via peer-relay(18.237.116.163:12345:vni:1) in 32ms
pong from tailscale-ec2-client-1 (100.116.238.16) via peer-relay(18.237.116.163:12345:vni:1) in 30ms
pong from tailscale-ec2-client-1 (100.116.238.16) via peer-relay(18.237.116.163:12345:vni:1) in 34ms
pong from tailscale-ec2-client-1 (100.116.238.16) via peer-relay(18.237.116.163:12345:vni:1) in 32ms
2025/12/06 09:53:40 direct connection not established
```

We are now using Tailscale's peer relay connectivity to get high peed, performant connections to another Tailscale client in a private subnet!





