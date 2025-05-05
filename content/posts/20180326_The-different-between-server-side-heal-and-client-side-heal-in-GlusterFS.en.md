---
title: The difference between server-side healing and client-side healing in GlusterFS
date: 2018-03-26 09:56:21
tags:
- GlusterFS
---

There are 2 kinds of healing functions in GlusterFS, server-side heal and client-side heal.

Server side heal is automatically executed by self-heal daemon on all gluster server nodes. It does healing by crawling file/directory information from .glusterfs directory on brick path. So it will keep the file-data and meta-data to be consistent from server side.

Client side heal is different, it will triggers heal for the particular file whenever client accesses files from mount path, which means a file operation on file descriptor. It will lead to some performance impact as every file access operation will go through extra set of function calls for file check and heal.
Client-side heal is enable by default, and can be turned off by below command

File data

```sh
gluster volume set <volume name> cluster.data-self-heal off
```

Entry data (contents/entries of a directory)

```sh
gluster volume set <volume name> cluster.entry-self-heal off
```

Meta data

```sh
gluster volume set <volume name> cluster.metadata-self-heal off
```

Note that turn off client side healing doesn't mean to compromise data
integrity and consistency. For file read pending xattr is evaluated for replica
copies and read will only served from correct copy. For file write new data
will be written on both replica bricks, and self-heal daemon on gluster node
will take care of these and will do healing if needed.
