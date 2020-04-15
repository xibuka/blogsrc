---
title: "Install Linux OS With Qemu CLI"
date: 2020-04-15T12:08:11+09:00
draft: false
tags:
- Linux
---

# Background
Sometimes you want to build a reproducer for some installation issues. Instead
of putting the actual CD-ROM in your machine, QEMU, a popular hardware
virtualization solution, could help you to test it on virtual machines. Qemu
can help you to do a GUI install with Desktop or live Server install ISO, or
use text-mode installation with a Server install CD.

# Install
```
$ sudo apt install qemu
```
And also you need a ISO for installation.

# simplefied case
```
$ qemu-system-x86_64 -cdrom ubuntu.iso
```
But above command should not work and will be a kernel panic.
Be default qemu will only allocates 128MB of memory by default which is not
enough in most case. And ther is no hard drive attached to the VM for the
instalation to complete.

# With a specified hard drive and a proper memory

```
$ qemu-img create -f qcow2 disk.qcow2 10G
Formatting 'disk.qcow2', fmt=qcow2 size=10737418240 cluster_size=65536 lazy_refcounts=off refcount_bits=16
$ qemu-system-x86_64 -cdrom ubuntu-18.04.4-desktop-amd64.iso \
                     -hda disk.qcow2                         \
                     -m 4096
```
But only use QEMU to run a instance will be very slow. You need to add
`-enable-kvm` option to let QEMU to run in KVM mode. To use this option you
need to make sure KVM is supported by your processor and kernel.

So, try below command and you can have a GUI to install the OS.
```
$ qemu-system-x86_64 -cdrom ubuntu-18.04.4-desktop-amd64.iso \
                     -hda disk.qcow2                         \
                     -m 4096                                 \
                     -kvm-enable
```

![install screen](/img/2020-04-15_13-57.png)

# Other scenarios

## With more than one disks
```
$ qemu-system-x86_64 -cdrom ubuntu.iso -hda disk1.qcow2 -hdb disk2.qcow2
```

## With a boot menu
```
$ qemu-system-x86_64 -boot menu=on -cdrom ubuntu.iso -hda disk.qcow2
```

## With physical USB drive (requires root, hdb is used to avoid conflict)
```
$ qemu-system-x86_64 -usb /dev/sdb1 -hdb disk.qcow2
```

## With an image as USB drive
```
$ qemu-system-x86_64 -usb usb.img -hdb disk.qcow2
```
# refers

http://manpages.ubuntu.com/manpages/bionic/man1/qemu-system.1.html
