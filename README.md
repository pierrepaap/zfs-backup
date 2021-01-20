# zfs-backup
Set of scripts I use for my zfs backups

Note : backup_zfs_init.sh is probably untested.
You can init your backups with :

zfs send -v <zpool/zfs> | zfs recv -Fduv <zbackup_pool>

Note2 : if you havs ZFS, I hope you thought of using a mirror or a raidz1 otherwise why use it :-)