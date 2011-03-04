#!/bin/bash

G_SVNSERVER=natal.tch.harvard.edu
G_SVNUSER=dicom
G_SVNTREEROOTDIR=/home/dicom
G_CHRISDIR=/home/dicom/chris
G_CONFIGDIR=/home/dicom/config
G_NEURODEBIAN_SOURCES=http://neuro.debian.net/_static/neurodebian.lucid.us-nh.sources.list
G_NEURODEBIAN_KEY_BASE=http://neuro.debian.net/_static
G_NEURODEBIAN_KEY=neuro.debian.net.asc
DIALOG=zenity


######################################################################
# Confirm installation
######################################################################
declare -i bInstall=0
declare -i bInstNeurodebian=0
declare -i bInstPackages=0
declare -i bInstSVN=0
declare -i bInstDICOM=0
declare -i bInstXinetd=0
declare -i bInstWt=0
declare -i bInstWebFrontEnd=0
declare -i bInstApache=0

response=$($DIALOG --list \
                   --text='Select CHRIS installation options' \
      	           --checklist \
	           --column='Enabled' \
                   --column='Stage' \
                   TRUE 'Neurodebian - add to Package Manager' \
                   TRUE 'Install Packages' \
                   TRUE 'Checkout CHB subversion tree' \
                   TRUE 'Create DICOM listener directory structures' \
                   TRUE 'xinetd - configure' \
                   TRUE 'Wt - build and install' \
                   TRUE 'Build and install web front-end' \
                   TRUE 'Apache - configure' --separator=':')


if [ -z "$response" ] ; then
    echo "Cancel"
    exit 1
fi

IFS=":"
for item in $response ; do
    case $item in
	Neuro*)     bInstNeurodebian=1 ;;
	Inst*)      bInstPackages=1    ;;
	Check*)     bInstSVN=1         ;;
	Create*)    bInstDICOM=1       ;;
	xinetd*)    bInstXinetd=1      ;;
	Wt*)        bInstWt=1          ;;
	Build*)     bInstWebFrontEnd=1 ;;
	Apache*)    bInstApache=1      ;;
    esac
done

unset IFS

# If we are installing the web front-end, ask about creating an
# admin account for the web GUI
declare -i bSetPassword=0
if (( bInstWebFrontEnd )) ; then
    $DIALOG --question --text="Would you like to create a user for the CHRIS web front-end?"
    response=$?
    if [ "${response}" == "0" ] ; then	
	G_USERNAME=$($DIALOG --entry --title="Add a User" --text="Enter _username:")
	if [ "$?" == "0" ] ; then
	    G_PASSWORD1="-x"
	    G_PASSWORD2="-y"
	    while [ "$G_PASSWORD1" != "$G_PASSWORD2" ] ; do	    
		G_PASSWORD1=$($DIALOG --entry --title="Add a User" --text="Enter _password:" --hide-text)
		if [ "$?" == "0" ] ; then
		    G_PASSWORD2=$($DIALOG --entry --title="Add a User" --text="Confirm _password:" --hide-text)
		    if [ "$?" != "0" ] ; then
			G_PASSWORD1=$G_PASSWORD2
			bSetPassword=0
		    else
			if [ "$G_PASSWORD1" != "$G_PASSWORD2" ] ; then
			    $DIALOG --error --text "Password entered did not match, please enter it again."
			fi
			bSetPassword=1
		    fi
		else
		    G_PASSWORD2=$G_PASSWORD1
		    bSetPassword=0
	        fi		
	    done
	fi
    fi
    G_PASSWORD=$G_PASSWORD1
fi


echo "Installing..."

######################################################################
# Add Neurodebian
######################################################################
if (( bInstNeurodebian )) ; then
    echo "CHRIS: Adding Neurodebian to sources..."
    cd /etc/apt/sources.list.d
    wget ${G_NEURODEBIAN_SOURCES}

    cd /tmp
    wget ${G_NEURODEBIAN_KEY_URL_BASE}/${G_NEURODEBIAN_KEY}
    apt-key add ${G_NEURODEBIAN_KEY}

    apt-get update
fi

######################################################################
# Install Packages
######################################################################
if (( bInstPackages )) ; then
    echo "CHRIS: Installing packages..."
    apt-get install fsl xvfb subversion dcmtk xinetd postfix \
	cmake libasio-dev libqt4-dev libboost-all-dev libssl-dev \
	cmake-curses-gui libfcgi-dev libapache2-mod-fastcgi apache2 libfcgi
fi

######################################################################
# Checkout subversion tree
######################################################################
if (( bInstSVN )) ; then
    echo "CHRIS: Checkout CHB subversion tree..."
    cd ${G_SVNTREEROOTDIR}
    svn checkout svn+ssh://${G_SVNUSER}@${G_SVNSERVER}/home/svn/chb
    cd chb
    svn update
    cd ..
    chown -R dicom:dicom chb
fi


######################################################################
# Create directory structure
######################################################################
if (( bInstDICOM )) ; then
    echo "CHRIS: Creating directory structure..."
    mkdir -p ${G_CHRISDIR}/files
    mkdir -p ${G_CHRISDIR}/incoming
    mkdir -p ${G_CHRISDIR}/log
    mkdir -p ${G_CHRISDIR}/postproc/example
    mkdir -p ${G_CHRISDIR}/postproc/projects
    chown -R dicom:dicom ${G_CHRISDIR}
fi

######################################################################
# Configure xinetd
######################################################################
if (( bInstXinetd )) ; then
    G_XINETDCFG=/etc/xinetd.d/dicom-chb
    echo "service dicom-chb" > ${G_XINETDCFG}
    echo "{" >> ${G_XINETDCFG}
    echo "  socket_type         = stream" >> ${G_XINETDCFG}
    echo "  wait                = no" >> ${G_XINETDCFG}
    echo "  user                = dicom" >> ${G_XINETDCFG} 
    echo "  group               = dicom" >> ${G_XINETDCFG}
    echo "  log_on_success      = HOST DURATION" >> ${G_XINETDCFG}
    echo "  log_on_failure      = HOST" >> ${G_XINETDCFG}
    echo "  server              = ${G_SVNTREEROOTDIR}/chb/trunk/scripts/storescp.wrapper" >> ${G_XINETDCFG}
    echo "  disable             = no" >> ${G_XINETDCFG}
    echo "  port                = 10401" >> ${G_XINETDCFG}
    echo "}" >> ${G_XINETDCFG}

    grep -q "dicom-chb 10401/tcp dicom" /etc/services 2> /dev/null || echo "dicom-chb 10401/tcp dicom" >> /etc/services
    grep -q "dicom-chb 10401/udp dicom" /etc/services 2> /dev/null || echo "dicom-chb 10401/udp dicom" >> /etc/services

    /etc/init.d/xinetd restart

    cd ${G_SVNTREEROOTDIR}
    ln -s ${G_SVNTREEROOTDIR}/chb/trunk/scripts/config_neuropipe_env.example.bash chb-env
fi


######################################################################
# Build and install Wt
######################################################################
if (( bInstWt )) ; then
    cd /tmp
    wget http://downloads.sourceforge.net/project/witty/wt/3.1.7/wt-3.1.7a.tar.gz
    tar xvf wt-3.1.7a.tar.gz
    cd wt-3.1.7a
    mkdir build
    cd build
    cmake ../ -DCONNECTOR_FCGI=ON -DEXAMPLES_CONNECTOR=wtfcgi
    make
    make install
fi

######################################################################
# Build and install the web front-end
######################################################################
if (( bInstWebFrontEnd )) ; then
    
    # Install dependencies
    cd ${G_SVNTREEROOTDIR}/chb/trunk/www/wt/third-party
    unzip -o process-is-0.4.zip
    cd process-is-0.4/boost
    cp -r * /usr/include/boost/

    cd ${G_SVNTREEROOTDIR}/chb/trunk/www/wt/third-party    
    tar xvf mxml-2.6.tar.gz
    cd mxml-2.6
    ./configure
    make
    make install

    # Build the pl_gui.wt web front-end
    cd ${G_SVNTREEROOTDIR}/chb/trunk/www/wt
    mkdir build
    cd build
    cmake ../ -DCONNECTOR_FCGI=ON -DEXAMPLES_CONNECTOR=wtfcgi
    make
    cd src/pl_gui
    ./deploy.sh

    # If generating the password database
    if (( bSetPassword )) ; then
	htpasswd -c ${G_CONFIGDIR}/pl_gui_htpasswd $G_USERNAME $G_PASSWORD

	G_PERMISSIONSXML=${G_CHRISDIR}/files/permissions.xml
	if [[ ! -f ${G_PERMISSIONSXML ]] ; then
	    echo "<?xml version=\"1.0\"?>" > $G_PERMISSIONSXML
	    echo "<Group name=\"admin\">" >> $G_PERMISSIONSXML
	    echo "  <User name=\"$G_USERNAME\" />" >> $G_PERMISSIONSXML
	    echo "</Group>" >> $G_PERMISSIONSXML
	    chown dicom:dicom ${G_PERMISSIONSXML}
	    chmod 600 ${G_PERMISSIONSXML}
	fi
    fi

    G_PLGUICONF=${G_SVNTREEROOTDIR}/chb/trunk/www/wt/src/pl_gui/conf/pl_gui.conf
    #sed -i 's/dicomDir.*=.*/dicomDir = $G_CHRISDIR\/files/g' ${G_PLGUICONF}
    

    # Create symbolic links to the config files
    mkdir -p ${G_CONFIGDIR}
    cd ${G_CONFIGDIR}
    ln -s -f ${G_SVNTREEROOTDIR}/chb/trunk/www/wt/src/pl_gui/conf/pl_gui.conf pl_gui.conf
    ln -s -f ${G_SVNTREEROOTDIR}/chb/trunk/www/wt/src/pl_gui/text.xml text.xml
    ln -s -f ${G_CHRISDIR}/files/permissions.xml permissions.xml
    chown -R dicom:dicom ${G_CONFIGDIR}

    # Copy the default wt_config.xml
    cp ${G_SVNTREEROOTDIR}/chb/trunk/www/wt/config/wt_config.xml /etc/wt/wt_config.xml
fi

######################################################################
# Configure Apache
######################################################################
if (( bInstApache )) ; then
    # Set fastcgi.conf for pl_gui
    G_FASTCGICONF=/etc/apache2/mods-enabled/fastcgi.conf
    grep pl_gui $G_FASTCGICONF > /dev/null
    if [ "$?" != "0" ] ; then
	echo "<IfModule mod_fastcgi.c>" > $G_FASTCGICONF
	echo "    AddHandler fastcgi-script .wt" >> $G_FASTCGICONF
	echo "    FastCgiServer /var/www/localhost/htdocs/pl_gui/pl_gui.wt" >> $G_FASTCGICONF
	echo "</IfModule>" >> $G_FASTCGICONF
    fi

    # Set the user to dicom
    sed -i 's/www-data/dicom/g' /etc/apache2/envvars
    
    # Create links for WebGL
    cd /var/www
    ln -s ${G_SVNTREEROOTDIR}/chb/trunk/www/webgl webgl
    ln -s ${G_CHRISDIR}/postproc postproc

    # If it hasn't already been done, add link to postproc folder
    # for WebGL viewer
    G_APACHE2CONF=/etc/apache2/apache2.conf
    grep postproc $G_APACHE2CONF > /dev/null
    if [ "$?" != "0" ] ; then
	echo "Alias ${G_CHRISDIR}/postproc /var/www/postproc" >> $G_APACHE2CONF
	echo "<Directory /var/www/postproc>" >> $G_APACHE2CONF
	echo "    AddHandler cgi-script .cgi .pl" >> $G_APACHE2CONF
        echo "    Options +Indexes +ExecCGI +FollowSymLinks" >> $G_APACHE2CONF
	echo "    DirectoryIndex index.cgi" >> $G_APACHE2CONF
	echo "    AllowOverride Limit" >> $G_APACHE2CONF
	echo "</Directory>" >> $G_APACHE2CONF
    fi

    # Change directory permissions
    chown -R dicom:dicom /var/run/wt/
    chown -R dicom:dicom /var/www
    mkdir -p /var/run/apache2/fastcgi
    chown -R dicom:dicom /var/run/apache2/fastcgi
    
    /etc/init.d/apache2 restart
fi

######################################################################
# Install ConnectomeViewer
######################################################################

######################################################################
# Install CMP Pipeline
######################################################################



echo "CHRIS: Exiting install."







