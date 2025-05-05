---
title: GlusterFS Failed to probe a cloned peer
date: 2017-06-15 11:43:46
tags:
- gluster
---
If you want to save some time for setup each gluster system, you can just setup all the necessary configuration in one vm, and then cloning it.
But you may in trouble for probe a peer from another node.
When you try to run the command, you could get the following error messages:

```bash
[root@node1 ~]# gluster peer probe node2
peer probe: failed: Peer uuid (host node2) is same as local uuid
```

this is because when glusterfs-server package is first installed, a node UUID
file will be created at /var/lib/glusterd/glusterd.info. So after you cloned
the vm that has installed glusterfs, the glusterd.info with same UUID will be
stored in all vms.

Here is the solution:

1. stop glusterd servie on all nodes
2. remove /var/lib/glusterd/glusterd.info
3. start glusterd servie on all nodes
4. run peer probe command again.

after step 3, a new glusterd.info file will be created with a new UUID, and the
issue will be resolved for good.
