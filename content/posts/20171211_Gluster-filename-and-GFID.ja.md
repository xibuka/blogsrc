---
title: 'Gluster ファイル名と GFID の相互変換'
date: 2017-12-11 15:41:23
tags:
- GlusterFS
---

## テストファイルの作成

gluster ボリュームをマウントしてファイルを作成します。

```bash
[root@client-1 ~]# mount -t glusterfs gluster-node-1:/vol /mnt
[root@client-1 ~]# mkdir -p /mnt/hoge/hello-gluster/
[root@client-1 ~]# touch /mnt/hoge/hello-gluster/file
[root@client-1 ~]# umount /mnt/
```

## Gluster ボリューム内のファイルの GFID を取得

### ブリックディレクトリから

gluster ノードにログインし、ブリックディレクトリ内のファイルを探します。

```bash
[root@gluster-node-1 ~]# gluster volume info vol

Volume Name: vol
Type: Replicate
Volume ID: 4ac36bcc-7127-48c4-ac21-421850d8bc47
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 3 = 3
Transport-type: tcp,rdma
Bricks:
Brick1: gluster-node-1:/gluster/brick-vol   <-- ブリックパスを確認
Brick2: gluster-node-2:/gluster/brick-vol
Brick3: gluster-node-3:/gluster/brick-vol
Options Reconfigured:
performance.readdir-ahead: on
nfs.disable: off
cluster.server-quorum-ratio: 51%
```

ブリック内のファイルパスを確認し、"trusted.gfid" で GFID を確認できます。

```bash
[root@gluster-node-1 ~]# ls /gluster/brick-vol/hoge/hello-gluster/file
/gluster/brick-vol/hoge/hello-gluster/file
[root@gluster-node-1 ~]# getfattr -d -m . -e hex /gluster/brick-vol/hoge/hello-gluster/file
getfattr: Removing leading '/' from absolute path names
# file: gluster/brick-vol/hoge/hello-gluster/file
security.selinux=0x73797374656d5f753a6f626a6563745f723a756e6c6162656c65645f743a733000
trusted.gfid=0xd8efc4c4d6204170ad293eda97d3d2e4
```

### クライアント側から

`-o aux-gfid-mount` オプション付きで gluster ボリュームをマウントします。

```bash
[root@gluster-node-1 ~]# mount -t glusterfs -o aux-gfid-mount gluster-node-1:/vol /mnt
```

マウントポイント内のファイルパスを確認し、`glusterfs.gfid.string` で GFID を確認できます。

```bash
[root@gluster-node-1 ~]# getfattr -n glusterfs.gfid.string /mnt/hoge/hello-gluster/file
getfattr: Removing leading '/' from absolute path names
# file: mnt/hoge/hello-gluster/file
glusterfs.gfid.string="d8efc4c4-d620-4170-ad29-3eda97d3d2e4"
```

## GFID からパス名への変換

### ツールによる変換

[https://gist.github.com/semiosis/4392640](https://gist.github.com/semiosis/4392640) を利用します。
※GFIDは XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX 形式である必要があります。

```bash
bash gfid-resolver.sh -h
Glusterfs GFID resolver -- turns a GFID into a real file path
 
Usage: gfid-resolver.sh <brick-path> <gfid> [-q]
  <brick-path> : the path to your glusterfs brick (required)
  
  <gfid> : the gfid you wish to resolve to a real path (required)
  
  -q : quieter output (optional)
       with this option only the actual resolved path is printed.
       without this option gfid-resolver.sh will print the GFID, 
       whether it identifies a file or directory, and the resolved
       path to the real file or directory.
 
Theory:
The .glusterfs directory in the brick root has files named by GFIDs
If the GFID identifies a directory, then this file is a symlink to the
actual directory.  If the GFID identifies a file then this file is a
hard link to the actual file.

[root@gluster-node-1 ~]# bash gfid-resolver.sh /gluster/brick-vol d8efc4c4-d620-4170-ad29-3eda97d3d2e4                                                                                                                                        
d8efc4c4-d620-4170-ad29-3eda97d3d2e4    ==      File:   /gluster/brick-vol/hoge/hello-gluster/file
```
