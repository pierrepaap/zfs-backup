#!/bin/sh

cd /path/to/your/scripts

# snapshots
./backup_zfs_snapshot.sh src_pool

# backups
./backup_zfs_USB.sh <src_zfs> <dest_pool>

# cleanup
sleep 300
./backup_zfs_cleanup.sh <src_zfs> <dest_pool>
