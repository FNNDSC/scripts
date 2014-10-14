#!/bin/bash

sudo mount -t cifs //10.3.1.214/MedCom /mnt/siemens_oc_longwood-3.0T -o uid=6244,gid=1102,user=meduser,password=meduser1
sudo mount -t cifs //10.3.1.214/Disk_C /mnt/siemens_oc_longwood-3.0T-Disk_C -o uid=6244,gid=1102,user=meduser,password=meduser1
