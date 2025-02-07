---
title: '[OpenShift]Quick install OpenShift to multi nodes'
date: 2017-07-07 15:32:15
tags:
- Linux
- OpenShift
---

In this article we will show you how to install OpenShift in mutliple nodes
using a quick install command, atomic-openshift-installer, which is powered by
ansible.

# Host preparation
I use under virtual machines for OpenShift nodes to deploy

|Type    | CPU | Mem  | HDD   | hostname            | OS     |
|------- | --- | ---- | ----- | ------------------- | ------ |
| Master | 1   | 2 GB | 20 GB | master.example.com  | RHEL 7 |
| node   | 1   | 2 GB | 20 GB | node1.example.com   | RHEL 7 |
| node   | 1   | 2 GB | 20 GB | node2.example.com   | RHEL 7 |

# Host Registration
Note: If you are using other OS but not RHEL, Please go to [# Install necessary packages](# Install necessary packages) to install the
packages. If you can not install some of them, try to add some repos or get the rpm file.

Register each host with RHSM(Red Hat Subscription Manager) to access the
required packages.

<!--more -->

1. Register with RHSM for each host:

   ```
   # subscription-manager register --username=<user_name> --password=<password>
   ```

2. List the available OpenShift subscriptions:

   ```
   # subscription-manager list --available --matches '*OpenShift*'
   ```

3. Find pool ID for an OpenShift Container Platform subscription and attach it.

   ```
   # subscription-manager attach --pool=<pool_id>
   ```

4. Disable all repositories and enable only the repositories required by
   OpenShift Container Platform 3.5

   ```
   # subscription-manager repos --disable="*"
   # yum-config-manager --disable \*
   # subscription-manager repos \
       --enable="rhel-7-server-rpms" \
       --enable="rhel-7-server-extras-rpms" \
       --enable="rhel-7-server-ose-3.5-rpms" \
       --enable="rhel-7-fast-datapath-rpms"
   ```

# Install necessary packages
Install the following packages.

   ```
   # yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec sos psacct
   # yum update
   # yum -y install atomic-openshift-utils atomic-openshift-excluder atomic-openshift-docker-excluder
   # atomic-openshift-excluder unexclude
   ```

# Install and configure docker

## Install docker

   ```
   # yum -y install docker
   ```

## Add parameter to docker configuration file

Edit `/etc/sysconfig/docker` file and add `--insecure-registry 172.30.0.0/16` to the `OPTIONS` parameter. 

   ```
   OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'
   ```

## Configure Docker Storage

Here we use an additional block device for docker storage. In `/etc/sysconfig/docker-storage-setup` , set `DEVS` to the path of the disk device. Set `VG` to the volume group name you wish to create.

   ```
   # cat <<EOF > /etc/sysconfig/docker-storage-setup
   DEVS=/dev/vdc
   VG=docker-vg
   EOF
   ```

Then run `docker-storage-setup` and check to make sure the `docker-vg` was created.

   ```
   # docker-storage-setup                                                                                                                                                                                                                                [5/1868]
   0
   Checking that no-one is using this disk right now ...
   OK
   
   Disk /dev/vdc: 31207 cylinders, 16 heads, 63 sectors/track
   sfdisk:  /dev/vdc: unrecognized partition table type
   
   Old situation:
   sfdisk: No partitions found
   
   New situation:
   Units: sectors of 512 bytes, counting from 0
   
      Device Boot    Start       End   #sectors  Id  System
   /dev/vdc1          2048  31457279   31455232  8e  Linux LVM
   /dev/vdc2             0         -          0   0  Empty
   /dev/vdc3             0         -          0   0  Empty
   /dev/vdc4             0         -          0   0  Empty
   Warning: partition 1 does not start at a cylinder boundary
   Warning: partition 1 does not end at a cylinder boundary
   Warning: no primary partition is marked bootable (active)
   This does not matter for LILO, but the DOS MBR will not boot this disk.
   Successfully wrote the new partition table
   
   Re-reading the partition table ...
   
   If you created or changed a DOS partition, /dev/foo7, say, then use dd(1)
   to zero the first 512 bytes:  dd if=/dev/zero of=/dev/foo7 bs=512 count=1
   (See fdisk(8).)
     Physical volume "/dev/vdc1" successfully created
     Volume group "docker-vg" successfully created
     Rounding up size to full physical extent 16.00 MiB
     Logical volume "docker-poolmeta" created.
     Logical volume "docker-pool" created.
     WARNING: Converting logical volume docker-vg/docker-pool and docker-vg/docker-poolmeta to pool's data and metadata volumes.
     THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)
     Converted docker-vg/docker-pool to thin pool.
     Logical volume "docker-pool" changed.
   ```

## Enable and start docker service.

   ```
   # systemctl enable docker
   # systemctl start docker
   # systemctl is-active docker
   ```

# Ensure Host Access
On each hosts, generate an SSH key WITHOUT a password

   ```
   # ssh-keygen
   ```
   
Copy the `id_rsa.pub` to each host:
   
   ```
   # for host in master.example.com \
       node1.example.com \
       node2.example.com; \
       do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
       done
   ```

# Quick Installation

## Running an Interactive Installation
Start the interactive installation by running under command, and follow the
on-screen instructions to install a new OpenShift Continer Platform cluster.

   ```
   $ atomic-openshift-installer install
   *** Installation Summary ***
   
   Hosts:
   - master.example.com
     - OpenShift master
     - OpenShift node (Unscheduled)
     - Etcd
     - Storage
   - node1.example.com
     - OpenShift node (Dedicated)
   - node2.example.com
     - OpenShift node (Dedicated)
   
   Total OpenShift masters: 1
   Total OpenShift nodes: 3
   
   NOTE: Add a total of 3 or more masters to perform an HA installation.
   
   Gathering information from hosts...
   All hosts in config are uninstalled. Proceeding with installation...
   
   Wrote atomic-openshift-installer config: /root/.config/openshift/installer.cfg.yml
   Wrote Ansible inventory: /root/.config/openshift/hosts
   
   Ready to run installation process.
   
   Play 1/28 (Create initial host groups for localhost)
   ..
   Play 2/28 (Create initial host groups for all hosts)
   .
   Play 3/28 (Populate config host groups)
   ................
   Play 4/28 (Ensure that all non-node hosts are accessible)
   .
   Play 5/28 (Initialize host facts)
   ................
   Play 6/28 (Gather and set facts for node hosts)
   ...............
   Play 7/28 (Verify compatible yum/subscription-manager combination)
   ..
   Play 8/28 (Determine openshift_version to configure on first master)
   ............................................................................................
   Play 9/28 (Set openshift_version for all hosts)
   ............................................................................................
   Play 10/28 (Set oo_option facts)
   ........
   Play 11/28 (Disable excluders)
   ..........................
   Play 12/28 (Configure etcd)
   ................................................................................................................................................Pausing for 10 seconds
   (ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
   ....................................................................
   Play 13/28 (Configure nfs)
   ...............................................
   Play 14/28 (Gather and set facts for master hosts)
   .......................
   Play 15/28 (Determine if session secrets must be generated)
   ..............
   Play 16/28 (Generate master session secrets)
   ..............
   Play 17/28 (Configure masters)
   .............................................................................................................................................................................................................................................................................................................................................................................................................................................
   Play 18/28 (Additional master configuration)
   .......................................................................................................................................................................................................................
   Play 19/28 (Gather and set facts for node hosts)
   ...............
   Play 20/28 (Evaluate node groups)
   ..
   Play 21/28 (Configure nodes)
   .............................................................................................................................................................................................................................................................................................................................................
   Play 22/28 (Additional node config)
   .....................................................................................................................
   Play 23/28 (Create persistent volumes)
   ............................................................................................................................................................
   Play 24/28 (Create Hosted Resources)
   .......................................................................................................................................................................................................Pausing for 30 seconds
   (ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
   ................................................
   Play 25/28 (Re-enable excluder if it was previously enabled)
   ...............
   localhost                  : ok=11   changed=0    unreachable=0    failed=0   
   master.example.com         : ok=606  changed=151  unreachable=0    failed=0   
   node1.example.com          : ok=202  changed=39   unreachable=0    failed=0   
   node2.example.com          : ok=202  changed=39   unreachable=0    failed=0   
   
   
   Installation Complete: Note: Play count is only an estimate, some plays may have been skipped or dynamically added
   
   
   The installation was successful!
   
   If this is your first time installing please take a look at the Administrator
   Guide for advanced options related to routing, storage, authentication, and
   more:
   
   http://docs.openshift.com/enterprise/latest/admin_guide/overview.html
   ```

## Running an unattended Installation 
Unattended installation allow you to run the installation with a pre-defined
configuration file. The default installation configure file path is *~/.config/openshift/installer.cfg.yml*. Define the configuration file and
run the install command with the `-u` option.

   ```
   $ atomic-openshift-installer -u install
   ```
Here is a simple example of the *install.cfg.yml* file. For further
information, please follow [Defining an Installation Configuration File](https://docs.openshift.com/container-platform/3.5/install_config/install/quick_install.html#defining-an-installation-configuration-file)

   ```~/.config/openshift/installer.cfg.yml
   ansible_callback_facts_yaml: /root/.config/openshift/.ansible/callback_facts.yaml
   ansible_inventory_path: /root/.config/openshift/hosts
   ansible_log_path: /tmp/ansible.log
   deployment:
     ansible_ssh_user: root
     hosts:
     - connect_to: master.example.com
       hostname: master
       ip: 10.64.221.200
       public_hostname: master
       public_ip: 10.64.221.200
       roles:
       - master
       - etcd
       - node
       - storage
     - connect_to: node1.example.com
       hostname: node1
       ip: 10.64.221.47
       node_labels: '{''region'': ''infra''}'
       public_hostname: node1
       public_ip: 10.64.221.47
       roles:
       - node
     - connect_to: node2.example.com
       hostname: node2
       ip: 10.64.221.192
       node_labels: '{''region'': ''infra''}'
       public_hostname: node2
       public_ip: 10.64.221.192
       roles:
       - node
     master_routingconfig_subdomain: ''
     openshift_master_cluster_hostname: None
     openshift_master_cluster_public_hostname: None
     proxy_exclude_hosts: ''
     proxy_http: ''
     proxy_https: ''
     roles:
       etcd: {}
       master: {}
       node: {}
       storage: {}
   variant: openshift-enterprise
   variant_version: '3.5'
   version: v2
   ```

Also you can specify a different path of the configuration file with the `-c` option.

   ```
   $ atomic-openshift-installer -u -c </path/to/file> install
   ```

## Verifying the installation
After the installation is completed.
1. Verify the master and nodes are started in Ready status. On the master host,
   run the following as root

   ```
   # oc get nodes
   
   NAME                        STATUS                     AGE
   master.example.com          Ready,SchedulingDisabled   165d
   node1.example.com           Ready                      165d
   node2.example.com           Ready                      165d
   ```

2. The web console use the master host name with a default port number 8443. In 
   this test environment, you can find the web console at [https://master.openshift.com:8443/console](https://master.openshift.com:8443/console)

3. Now that the install has been verified, run the following command on each master 
   and node host to add the atomic-openshift packages back to the list of yum 
   excludes on the host:

   ```
   # atomic-openshift-excluder exclude
   ```

# Uninstallation

You can uninstall OpenShift Container Platform from all hosts using the follow
commands

   ```
   $ atomic-openshift-installer uninstall
   OpenShift will be uninstalled from the following hosts:
   
     * master.example.com
     * node1.example.com
     * node2.example.com
   
   Do you want to proceed? [y/N]: y
   
   Play 1/9 (OSEv3:children)
   ....
   Play 2/9 (nodes)
   ..
   Play 3/9 (masters)
   ..
   Play 4/9 (etcd)
   ..
   Play 5/9 (nodes)
   ...............................
   Play 6/9 (masters)
   ............
   Play 7/9 (etcd)
   ............
   master.example.com         : ok=60   changed=17   unreachable=0    failed=0
   node1.example.com          : ok=35   changed=8    unreachable=0    failed=0
   node2.example.com          : ok=35   changed=8    unreachable=0    failed=0
   ```

If you are using a configuration file, specify the file path for the uninstallation:

   ```
   $ atomic-openshift-installer -c </path/to/file> uninstall
   ```
