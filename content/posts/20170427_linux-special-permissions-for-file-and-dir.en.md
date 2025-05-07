---
title: Special Permissions for Files and Directories
date: 2017-04-27 23:59:20
tags:
- Linux
---

## Explanation of Special Permissions

There are three special permissions for files and folders: setuid, setgid, and sticky bit.
The setuid and setgid permissions mean that a command is executed as the file owner or group, not as the user or group who ran the command.
The sticky bit permission imposes special restrictions on file deletion: only the file owner and root can delete files in the directory.

Special Permission | Effect on Files | Effect on Directories
-------------------|------------------|-----------------
u+s (suid)         | The file is executed as the file owner, not as the user who ran it. | No effect
g+s (sgid)         | The file is executed as the group owner. | Newly created files in the directory inherit the directory's group.
o+t (sticky)       | No effect         | Users with write permission to the directory can only delete files they own. They cannot delete or modify files owned by others.

## Setting Special Permissions

Symbolic: setuid = u+s; setgid = g+s; sticky = o+t
Numeric:  setuid = 4;   setgid = 2;   sticky = 1

Examples

```bash
chmod g+s file  # Add setgid bit to file
chmod 1755 file # Add sticky bit to file
```
