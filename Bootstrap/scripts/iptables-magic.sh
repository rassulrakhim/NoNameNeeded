#/bin/bash

floating_subnet="10.111.0.0/24"
floating_gateway="10.111.0.1"

docker exec openvswitch_vswitchd ip a add $floating_gateway dev br-ex
docker exec openvswitch_vswitchd ip link set br-ex up
docker exec openvswitch_vswitchd ip link set dev br-ex mtu 1400  # Ensure correct ssh connection

ip r a "$floating_subnet" via $floating_gateway dev br-ex

iptables -t nat -A POSTROUTING -o enp2s0 -j MASQUERADE

iptables -A FORWARD -i enp2s0 -o br-ex -j ACCEPT
iptables -A FORWARD -i br-ex -o enp2s0 -j ACCEPT
