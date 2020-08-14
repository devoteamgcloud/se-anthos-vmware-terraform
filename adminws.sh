#! /bin/bash

# Elevate to correct privileges
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Back to base path
cd ~

# Variables passed from terraform
USER_PASSWORD=$1

# Save connection variable for Admin WS
connect=$(tail gke-admin-ws-* | grep "ssh -i")
connect+=" -tt"

# Save IP variable to admin WS
sed -i "s~IP: ~~" gke-admin*
IP=$(tail gke-admin-* | grep "^192")

# Add Admin WS to known hosts
ssh-keyscan -H $IP >> ~/.ssh/known_hosts

# Connect to Admin WS
$connect <<'EOT'

# Variables
USER_PASSWORD=
NetworkServices=192.168.86.33
InstallVM=192.168.86.20

# Install sshpass
sudo apt install sshpass -y

# Add InstallVM to known hosts
ssh-keyscan -H $InstallVM >> ~/.ssh/known_hosts

# Add routes on Admin WS  to reach networks behind NetworkServicesVM
sudo ip route add 172.16.116.0/24 via $NetworkServices
sudo ip route add 192.168.116.0/24 via $NetworkServices

# Copy required service accounts from InstallVM
sshpass -p $USER_PASSWORD scp delta@$InstallVM:/home/delta/stackdriver-key.json .


# Create and modify required files for admin-cluster

echo "hostconfig:
  dns: 192.168.86.1
  tod: 0.se.pool.ntp.org
  otherdns:
  - 8.8.8.8
  - 8.8.4.4
  othertod:
  - ntp.ubuntu.com
blocks:
  - netmask: 255.255.255.0
    gateway: 172.16.116.1
    ips:
    - ip: 172.16.116.10
      hostname: admin-host1
    - ip: 172.16.116.11
      hostname: admin-host2
    - ip: 172.16.116.12
      hostname: admin-host3
    - ip: 172.16.116.13
      hostname: admin-host4
    - ip: 172.16.116.14
      hostname: admin-host5
" > admin-hostconfig.yaml

echo "hostconfig:
  dns: "192.168.86.1"
  tod: "0.se.pool.ntp.org"
  otherdns:
  - "8.8.8.8"
  - "8.8.4.4"
  othertod:
  - "ntp.ubuntu.com"
blocks:
  - netmask: "255.255.255.0"
    gateway: "172.16.116.1"
    ips:
    - ip: "172.16.116.18"
      hostname: "seesaw-vm"
" > admin-seesaw-hostconfig.yaml

sed -i "s~  dataDisk: \"\"~  dataDisk: \"admin-disk2.vmdk\"~" admin-cluster.yaml
sed -i "s~    type: dhcp~    type: static~" admin-cluster.yaml
sed -i "s~    # ipBlockFilePath: \"\"~    ipBlockFilePath: \"/home/ubuntu/admin-hostconfig.yaml\"~" admin-cluster.yaml
sed -i "s~    networkName: VM Network~    networkName: \"Admin Network\"~" admin-cluster.yaml
sed -i "s~    controlPlaneVIP: \"\"~    controlPlaneVIP: \"172.16.116.4\"~" admin-cluster.yaml
sed -i "s~    ipBlockFilePath: \"\"~    ipBlockFilePath: \"admin-seesaw-hostconfig.yaml\"~" admin-cluster.yaml
sed -i "s~    vrid: 0~    vrid: 172~" admin-cluster.yaml
sed -i "s~    masterIP: \"\"~    masterIP: \"172.16.116.7\"~" admin-cluster.yaml
sed -i "s~  projectID: \"\"~  projectID: \"anthos-sandbox-256114\"~" admin-cluster.yaml
sed -i "s~  clusterLocation: \"\"~  clusterLocation: \"europe-north1\"~" admin-cluster.yaml
sed -i "s~  serviceAccountKeyPath: \"\"~  serviceAccountKeyPath: \"/home/ubuntu/stackdriver-key.json\"~" admin-cluster.yaml


# Copy required service accounts from InstallVM
sshpass -p $USER_PASSWORD scp delta@$InstallVM:/home/delta/connect-key.json .
sshpass -p $USER_PASSWORD scp delta@$InstallVM:/home/delta/stackdriver-key.json .
sshpass -p $USER_PASSWORD scp delta@$InstallVM:/home/delta/register-key.json .


# Create and modify required files for user-cluster

echo "hostconfig:
  dns: "192.168.86.1"
  tod: "0.se.pool.ntp.org"
  otherdns:
  - 8.8.8.8
  - 8.8.4.4
  othertod:
  - ntp.ubuntu.com
blocks:
  - netmask: 255.255.252.0
    gateway: 192.168.116.1
    ips:
    - ip: 192.168.116.15
      hostname: user-host1
    - ip: 192.168.116.16
      hostname: user-host2
    - ip: 192.168.116.17
      hostname: user-host3
" > user-hostconfig.yaml

echo "hostconfig:
  dns: "192.168.86.1"
  tod: "0.se.pool.ntp.org"
  otherdns:
  - "8.8.8.8"
  - "8.8.4.4"
  othertod:
  - "ntp.ubuntu.com"
blocks:
  - netmask: "255.255.255.0"
    gateway: "192.168.116.1"
    ips:
    - ip: "192.168.116.18"
      hostname: "seesaw-vm"
" > user-seesaw-hostconfig.yaml

sed -i "s~name: \"\"~name: \"stockholm-gke-cluster\"~" user-cluster.yaml
sed -i "s~    type: dhcp~    type: static~" user-cluster.yaml
sed -i "s~    # ipBlockFilePath: \"\"~    ipBlockFilePath: \"/home/ubuntu/user-hostconfig.yaml\"~" user-cluster.yaml
sed -i "s~    networkName: VM Network~    networkName: \"User Network\"~" user-cluster.yaml
sed -i "s~    controlPlaneVIP: \"\"~    controlPlaneVIP: \"172.16.116.112\"~" user-cluster.yaml
sed -i "s~    ingressVIP: \"\"~    ingressVIP: \"192.168.116.3\"~" user-cluster.yaml
sed -i "s~    ipBlockFilePath: \"\"~    ipBlockFilePath: \"user-seesaw-hostconfig.yaml\"~" user-cluster.yaml
sed -i "s~    vrid: 0~    vrid: 192~" user-cluster.yaml
sed -i "s~    masterIP: \"\"~    masterIP: \"192.168.116.7\"~" user-cluster.yaml
sed -i "s~- name: pool-1~- name: sthlm-pool-1~" user-cluster.yaml
sed -i "s~  projectID: \"\"~  projectID: \"anthos-sandbox-256114\"~" user-cluster.yaml
sed -i "s~  clusterLocation: \"\"~  clusterLocation: \"europe-north1\"~" user-cluster.yaml
sed -i "s~  serviceAccountKeyPath: \"\"~  serviceAccountKeyPath: \"/home/ubuntu/stackdriver-key.json\"~" user-cluster.yaml
sed -i "s~  registerServiceAccountKeyPath: \"\"~  registerServiceAccountKeyPath: \"/home/ubuntu/register-key.json\"~" user-cluster.yaml
sed -i "s~  agentServiceAccountKeyPath: \"\"~  agentServiceAccountKeyPath: \"/home/ubuntu/connect-key.json\"~" user-cluster.yaml

# Create admin-cluster
# Run gkectl prepare to initialize your vSphere environment
gkectl prepare --config admin-cluster.yaml
# Create and configure the VM for your Seesaw load balancer
gkectl create loadbalancer --config admin-cluster.yaml
# Create your admin cluster
gkectl create admin --config admin-cluster.yaml

# Create user-cluster
# Create and configure the VM for your Seesaw load balancer
gkectl create loadbalancer --kubeconfig kubeconfig --config user-cluster.yaml
# Create your user cluster
gkectl create cluster --kubeconfig kubeconfig --config user-cluster.yaml

# Logout
exit
EOT

# Logout
exit

# End of script