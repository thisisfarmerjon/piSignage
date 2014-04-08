#!/bin/bash

echo "Installing PiSignage"


echo "Updating/Upgrading system packages"
sudo apt-get -qq update
sudo apt-get -y -qq upgrade
sudo apt-get -y remove wolfram* zenity*
sudo apt-get -y remove midori scratch gdb  build-essential g++ gcc dillo galculator sonic-pi wpagui pistore netsurf-gtk
sudo apt-get -y remove nano man-db leafpad gpicview xpdf weston qdbus manpages-dev
sudo apt-get -y autoremove
sudo rm -rf /var/cache/apt/archives/*


echo "Installing dependencies..."
sudo apt-get -y install git-core  uzbl omxplayer x11-xserver-utils chkconfig unclutter liblockdev1-dev read-edid watchdog fbi imagemagick

echo "Increasing swap space to 500MB..."
#echo "CONF_SWAPSIZE=500" > ~/dphys-swapfile
#sudo cp /etc/dphys-swapfile /etc/dphys-swapfile.bak
#sudo mv ~/dphys-swapfile /etc/dphys-swapfile


echo "Adding pisignage auto startup"
cp ~/piSignage/client/misc/start.sh ~/
sudo mv /etc/xdg/lxsession/LXDE/autostart /etc/xdg/lxsession/LXDE/autostart.bak
sudo cp ~/piSignage/client/misc/autostart /etc/xdg/lxsession/LXDE/


echo "Making modifications to X..."
#[ -f ~/.gtkrc-2.0 ] && rm -f ~/.gtkrc-2.0
# Do we need this ????
#ln -s ~/piSignage/client/misc/gtkrc-2.0 ~/.gtkrc-2.0

[ -f ~/.config/openbox/lxde-rc.xml ] && mv ~/.config/openbox/lxde-rc.xml ~/.config/openbox/lxde-rc.xml.bak
[ -d ~/.config/openbox ] || mkdir -p ~/.config/openbox
ln -s ~/piSignage/client/misc/lxde-rc.xml ~/.config/openbox/lxde-rc.xml
[ -f ~/.config/lxpanel/LXDE/panels/panel ] && mv ~/.config/lxpanel/LXDE/panels/panel ~/.config/lxpanel/LXDE/panels/panel.bak
sudo sed -e 's/^#xserver-command=X$/xserver-command=X -nocursor -s 0 dpms/g' -i /etc/lightdm/lightdm.conf

# Let monitor be on Always
sudo sed -e 's/^BLANK_TIME=.*/BLANK_TIME=0/g' -i /etc/kbd/config
sudo sed -e 's/^POWERDOWN_TIME=.*/POWERDOWN_TIME=0/g' -i /etc/kbd/config

echo "Enabling Watchdog..."
#sudo cp /etc/modules /etc/modules.bak
#sudo sed '$ i\bcm2708_wdog' -i /etc/modules
#sudo chkconfig watchdog on
#sudo cp /etc/watchdog.conf /etc/watchdog.conf.bak
#sudo sed -e 's/#watchdog-device/watchdog-device/g' -i /etc/watchdog.conf
#sudo /etc/init.d/watchdog start


# Make sure we have 32bit framebuffer depth; but alpha needs to go off due to bug.
if grep -q framebuffer_depth /boot/config.txt; then
  sudo sed 's/^framebuffer_depth.*/framebuffer_depth=32/' -i /boot/config.txt
else
  echo 'framebuffer_depth=32' | sudo tee -a /boot/config.txt > /dev/null
fi

# Fix frame buffer bug
if grep -q framebuffer_ignore_alpha /boot/config.txt; then
  sudo sed 's/^framebuffer_ignore_alpha.*/framebuffer_ignore_alpha=1/' -i /boot/config.txt
else
      echo 'framebuffer_ignore_alpha=1' | sudo tee -a /boot/config.txt > /dev/null
fi

# enable overscan to take care of HD ready 720p, older TVs
sudo sed 's/.*disable_overscan.*/disable_overscan=1/' -i /boot/config.txt
#sudo sed 's/.*overscan_left.*/overscan_left=4/' -i /boot/config.txt
#sudo sed 's/.*overscan_right.*/overscan_right=4/' -i /boot/config.txt
#sudo sed 's/.*overscan_top.*/overscan_top=4/' -i /boot/config.txt
#sudo sed 's/.*overscan_bottom.*/overscan_bottom=4/' -i /boot/config.txt
sudo sed 's/.*hdmi_force_hotplug.*/hdmi_force_hotplug=1/' -i /boot/config.txt
# selecting CEA 720p at 60Hz convert videos and images to 1280x720 size
sudo sed 's/.*hdmi_group.*/hdmi_group=1/' -i /boot/config.txt
sudo sed 's/.*hdmi_mode.*/hdmi_mode=4/' -i /boot/config.txt

# set gpu mem to 128MB
if grep -q gpu_mem /boot/config.txt; then
  sudo sed 's/^gpu_mem.*/gpu_mem=128/' -i /boot/config.txt
else
      echo 'gpu_mem=128' | sudo tee -a /boot/config.txt > /dev/null
fi


echo "Installing nodejs 10.24"
wget http://nodejs.org/dist/v0.10.24/node-v0.10.24-linux-arm-pi.tar.gz
tar -xvzf node-v0.10.24-linux-arm-pi.tar.gz
sudo mkdir /opt/node
sudo cp -R node-v0.10.24-linux-arm-pi/* /opt/node
rm -r node-v0.10.24-linux-arm-pi
sudo ln -s /opt/node/bin/node /usr/bin/node
sudo ln -s /opt/node/lib/node /usr/lib/node
sudo ln -s /opt/node/bin/npm /usr/bin/npm

echo "configure piSignage"
#git clone git://github.com/ariemtech/piSignage.git ~/piSignage
cd ~/piSignage/client
npm install

#create ~/.bash_profile file
[ -f ~/.bash_profile ] && mv ~/.bash_profile ~/.bash_profile.bak
sudo cp ~/piSignage/client/misc/bash_profile ~/.bash_profile
echo ". ~/.bash_profile" >> ~/.bashrc

echo "getting forever to run the server"
sudo /opt/node/bin/npm install forever -g
sudo ln -s /opt/node/bin/forever /usr/bin/forever

echo "Enable Usb tethering"
sudo cp /etc/network/interfaces  /etc/network/interfaces.bak
sudo cp ~/piSignage/client/misc/interfaces /etc/network/interfaces

echo " Raspbian Libcec: removed compilation: just install complied lib and bin"
#cd ~
#sudo apt-get -y install build-essential autoconf liblockdev1-dev libudev-dev git libtool pkg-config
#git clone git://github.com/Pulse-Eight/libcec.git
#cd libcec
#./bootstrap
#./configure --with-rpi-include-path=/opt/vc/include --with-rpi-lib-path=/opt/vc/lib --enable-rpi
#make
#sudo make install
#rm -R libcec

cd /usr/local/lib
sudo cp ~/piSignage/client/cec/libcec.*  /usr/local/lib
sudo cp ~/piSignage/client/cec/cec*  /usr/local/bin

sudo ln -s libcec.so.2.0.1 libcec.so.2
sudo ln -s libcec.so.2.0.1  libcec.so

#sudo rm  /usr/local/lib/libcec*
#sudo rm  /usr/local/bin/cec*

sudo ldconfig

#cec-client -l
#force to HDMI
#echo "as" | cec-client -s

#on the TV
#echo "on 0" | cec-client -s
#Off
#echo 'standby 0' | cec-client -s
#cec-client -s for monitoring

#echo h | cec-client -s -d 1

#Power status
#echo pow 0 | cec-client -d 1 -s


#allow-hotplug wlan0
#iface wlan0 inet manual
#wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
#iface default inet dhcp

echo "Quiet the boot process..."
sudo cp /boot/cmdline.txt /boot/cmdline.txt.bak
sudo cp ~/piSignage/client/misc/cmdline.txt /boot/cmdline.txt
#sudo sed 's/$/ quiet/' -i /boot/cmdline.txt

echo "Install btsync on pi"
#echo "download the btsync_arm.tar.gz from http://www.bittorrent.com/sync/downloads"
#echo "scp btsync_arm.tar.gz pi@yourpiip:/home/pi

cp ~/piSignage/btsync/bin/btsync_rpi.tar.gz ~/
tar -xvzf btsync_rpi.tar.gz
sudo mv /home/pi/btsync   /usr/bin/

echo "Installing btsync conf to ~"
#echo "copy the config file to ~"
cp ~/piSignage/btsync/btsync.conf ~/.btsync.conf

echo "Adding it to init at start"
sudo cp ~/piSignage/btsync/btsyncRpi-initd /etc/init.d/btsync
sudo chmod +x /etc/init.d/btsync
sudo update-rc.d btsync defaults

echo "copy the splash screen using fbi"
cp ~/piSignage/client/media/pisplash* ~/
sudo cp ~/piSignage/client/misc/asplashscreen /etc/init.d/
sudo chmod a+x /etc/init.d/asplashscreen
sudo insserv /etc/init.d/asplashscreen


echo "Restart the Pi"
#cat /proc/cpuinfo |grep Serial|awk '{print $3 }'
sudo curl -L --output $(which rpi-update) https://github.com/Hexxeh/rpi-update/raw/master/rpi-update
sudo rpi-update

echo "resize the SD card"
sudo sh /home/pi/piSignage/client/misc/rpi-wiggle

sudo reboot