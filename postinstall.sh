#!/bin/bash

## Output log file
OUTPUT_LOG=/Users/$USER/Desktop/install.log
echo > $OUTPUT_LOG
systemsetup -setremotelogin on

## Make PATH to bin accessible
export PATH=$PATH:/usr/local/bin/

echo "Installing xcode command line tools" >> $OUTPUT_LOG
## Install xcode commandline tools, ignore if already installed
sudo -u $USER /usr/bin/touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress 2>&1 1>>$OUTPUT_LOG
VERSION=$(sw_vers -productVersion | grep  -E "10\.[0-9]*" -o)
PROD=$(softwareupdate -l |
  grep "\*.*Command Line.*$VERSION.*" |
  head -n 1 | awk -F"*" '{print $2}' |
  sed -e 's/^ *//' |
  tr -d '\n')
echo $PROD 2>&1 1>>$OUTPUT_LOG
softwareupdate -i "$PROD" --verbose 2>&1 1>>$OUTPUT_LOG;

## Add self autorization for ssh
mkdir -p ~/.ssh/
chown $USER ~/.ssh/
echo "n" | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
mkdir -p /Users/$USER/.ssh/
chown $USER /Users/$USER/.ssh/

cat ~/.ssh/id_rsa.pub >> /Users/$USER/.ssh/authorized_keys
cat /Users/$USER/.ssh/id_rsa.pub >> /Users/$USER/.ssh/authorized_keys
chown $USER /Users/$USER/.ssh/id_rsa*


## Execute commands using ssh to preserve environment settings
run(){
	COMMAND=$1
	echo "Command: "$COMMAND   2>&1 1>>$OUTPUT_LOG
	COMMAND="export PATH=$PATH:/usr/local/bin/;"$COMMAND
	ssh -tt -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no $USER@localhost $COMMAND  2>&1 1>>$OUTPUT_LOG
	if grep -q "Failed to download resource" "$OUTPUT_LOG"; then
	   exit 1
	fi
}


## Install brew
sudo mkdir -p /usr/local/Cellar /usr/local/Homebrew /usr/local/Frameworks /usr/local/opt /usr/local/sbin /usr/local/share/zsh /usr/local/share/zsh/site-functions
sudo mkdir -p /usr/local/etc /usr/local/include /usr/local/var
chown -R $USER -p /usr/local/etc /usr/local/include /usr/local/var
chown -R $USER:admin /usr/local/Frameworks /usr/local/sbin
sudo mkdir -p /usr/local/Homebrew
chown -R $USER /usr/local/Homebrew

sudo mkdir -p /usr/local/Cellar
chown -R $USER /usr/local/Cellar

sudo -u $USER chmod -R u+rwx /usr/local/Frameworks /usr/local/sbin
sudo -u $USER mkdir -p /Users/$USER/Library/Caches/Homebrew
sudo -u $USER mkdir -p /Library/Caches/Homebrew


sudo -u $USER mkdir -p /usr/local/share/
chown -R $USER /usr/local/share/

chown -R $USER /usr/local/opt

run 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null'
mkdir /usr/local/Caskroom/
chown -R $USER:admin /usr/local/Caskroom/

## Install brew depedencies
run "brew doctor"
run "brew install wget"

## Install nvidia-cuda
mkdir -p /tmp/nvidia-cuda
cd /tmp/nvidia-cuda
if [ ! -f cuda_9.0.176_mac-dmg ]; then
	if [ ! -d /Developer/NVIDIA/9.0 ]; then
		rm -R /Developer
	fi
	wget https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_mac-dmg 2>&1 1>>$OUTPUT_LOG
fi
hdiutil attach cuda_9.0.176_mac-dmg
cd /Volumes/CUDAMacOSXInstaller
CUDAMacOSXInstaller.app/Contents/MacOS/CUDAMacOSXInstaller --accept-eula --silent 2>&1 1>>$OUTPUT_LOG
chown -R $USER /usr/local/cuda

## Install brew depedencies
run "brew install -vd snappy leveldb gflags glog szip lmdb;"
run "brew tap homebrew/science; brew install hdf5 opencv "
run "brew upgrade libpng"
run "brew install --build-from-source --with-python -vd protobuf"
run "brew install --build-from-source -vd boost boost-python"
run "brew install --fresh -vd openblas"
run "brew install numpy"


## Make miles-deep binary
cd /Applications/MilesDeepUI.app/Contents/Resources/miles-deep
make superclean 2>&1 1>>$OUTPUT_LOG
make  2>&1 1>>$OUTPUT_LOG

chown -R $USER /tmp
chown -R $USER:staff /Applications/MilesDeepUI.app/Contents/Resources/miles-deep

echo "Enjoy!" 2>&1 1>>$OUTPUT_LOG

