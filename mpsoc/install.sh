#!/bin/bash

# run the following line in terminal to install the necessary packages
#    sudo bash install.sh 




shel=$(ps -p $$);
shel=${shel##* }

if [ "$shel" !=  "bash" ] 
then
  echo "make sure that you source this script in a bash shell"
  echo "The current shel is ($shel), aborting" 
  exit
fi
if [ $SUDO_USER ]; then user=$SUDO_USER; else user=`whoami`; fi

#the current script path
	SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
	SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)







#list of packages
LIST_OF_APPS="build-essential  libpango1.0-dev clang lib32z1 libgd-graph-perl libgd-gd2-perl libglib-perl cpanminus libusb-1.0 graphviz libcanberra-gtk-module unzip xterm verilator wget python python-pip curl" 

PERL_LIBS="ExtUtils::Depends ExtUtils::PkgConfig Glib Pango String::Similarity  IO::CaptureOutput Proc::Background List::MoreUtils File::Find::Rule  Verilog::EditFiles IPC::Run File::Which Class::Accessor String::Scanf File::Copy::Recursive  GD::Graph::bars3d GD::Graph::linespoints GD::Graph::Data constant::boolean Event::MakeMaker Glib::Event Chart::Gnuplot" 



APP_GTK2="libgtk2.0-dev libglib2.0-dev libgtk2-perl libgtksourceview2.0-dev" 
PERL_GTK2="Gtk2 Gtk2::SourceView2" 
APP_GTK3="libgtk-3-dev libglib3.0-cil-dev libgtk3-perl libgtksourceview-3.0-dev" 
PERL_GTK3="Gtk3  Gtk3::SourceView" 


#choose GTK version: 2 or 3. 
echo "Enter the version of GTK you want to install ProNoC for: 2 or 3 (3 is recommended)?"
read gtk_version

while ! [ "${gtk_version}" = '2' -o "${gtk_version}" = '3' ]; do
	echo "Wrong version number 2 or 3?"
	read gtk_version
done 



#update GTK version in Consts file
echo "#This file is created by ${SCRPT_DIR_PATH}/intsall.sh
package Consts;

use constant VERSION  => '2.1.0'; 
use constant END_YEAR => '2022';
use constant GTK_VERSION => '$gtk_version';


1;

" > ${SCRPT_DIR_PATH}/perl_gui/lib/perl/Consts.pm



function aptget_array {
	#Call apt-get for each package
	arr=("$@")
   	for pkg in "${arr[@]}"
	do
	    sudo apt-get -y install $pkg
	done
	
}




if [ "${gtk_version}" = '2' ]
then 
	echo "Install ProNoC GUI with GTK2"
	aptget_array $LIST_OF_APPS
	aptget_array $APP_GTK2
	cpanm $PERL_LIBS
	cpanm $PERL_GTK2
else 
	echo "Install ProNoC GUI with GTK3"
	aptget_array $LIST_OF_APPS
	aptget_array $APP_GTK3
	cpanm $PERL_LIBS
	cpanm $PERL_GTK3
fi

#install icon
cp $SCRPT_DIR_PATH/perl_gui/icons/ProNoC.png  /usr/local/share/icons/hicolor/128x128/apps/
cp $SCRPT_DIR_PATH/perl_gui/icons/ProNoC.svg  /usr/local/share/icons/hicolor/scalable/apps/

#install python
echo "install python" 
apt-get install -y python2
echo "install python-pipe. Installation may take several minutes" 
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
sudo python2 get-pip.py 
pip install trueskill numpy "networkx<2.0"

#make pronoc application/executable file
cd $SCRPT_DIR_PATH/src_c/app_executable
make
mv ./ProNoC $SCRPT_DIR_PATH/perl_gui/
chown -R $user $SCRPT_DIR_PATH/perl_gui/ProNoC 
echo "pronoc application/executable file is generated!"
cd $SCRPT_DIR_PATH



