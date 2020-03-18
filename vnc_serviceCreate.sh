#!/bin/bash 

# "include" the set of common script functions
source common.bash


bg="black"
fg="purple"
HOME="/home/rudolph"
USER="rudolph"
GROUP="grantlab"
geometry="1920x1080"
depth="24"

G_SYNOPSIS="

  NAME

        vnc_serviceCreate.sh

  SYNOPSIS
  
        vnc_serviceCreate.sh    -H <homeDir>                            \\
                                -U <user>                               \\
                                -G <group>                              \\
                                [-g <geometry>]                         \\
                                [-d <depth>]                            \\
                                [-v <verbosityLevel>]   

  DESC

        'vnc_serviceCreate.sh' simply creates the service file for
        a vnc user.

  ARGS
  
        -H <homeDir>
        The <homeDir> spec to create.
        
        -U <user>
        The username to run the service.
        
        -G <group>
        The <user>'s <group>.
        
        [-g <geometry>]
        The geometry of the display window. 
        Default: 1920x1080
        
        [-d <depth>]
        The color depth.
        Default: 24

  EXAMPLES

        $> vnc_serviceCreate.sh -H /home/rudolph        \\
                                -U rudolph              \\
                                -G fnndsc               \\
                                -g 1920x1080            \\
                                -d 24  > service.txt
        
        Creates a service file with the given specs as per 
        CLI args.

"

while getopts v:H:U:G:g:d: option ; do
    case "$option" 
    in
        H) HOME=$OPTARG                 ;;
        U) USER=$OPTARG                 ;;
        G) GROUP=$OPTARG                ;;
        g) geometry=$OPTARG             ;;
        d) depth=$OPTARG                ;;
        v) Gi_verbose=$OPTARG           ;;
        \?) synopsis_show                
            exit 1;;
    esac
done

if(( ${#HOME} )) ; then

        IFS='' read -r -d '' String <<EOF
[Unit]
Description=Start system VNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$USER
Group=$GROUP
WorkingDirectory=$HOME

PIDFile=${HOME}/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth $depth -geometry $geometry :%i -localhost no
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target        
EOF
        echo "${String}"

fi



