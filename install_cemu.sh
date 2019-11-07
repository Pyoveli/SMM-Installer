#!/bin/bash

#*************************************************************
#* Pre-Intall Checks (Required software for install and wine * 
#*************************************************************

# If run as root, exit... 
if (( $EUID == 0 )); then
	echo "Do not run as root."
	exit 1
fi

if [ -z "$DISPLAY" ]; then
	export DISPLAY=:0.0
fi

# Check required depencies if missing then tell whics is missing and how to install them
declare -a reqsw=("wine" "bsdtar" "unzip" "glxinfo" "curl" "wget" "winetricks" "screen")
for i in "${reqsw[@]}"
do
	if ! [ -x "$(command -v $i)" ]; then
		echo "You must install $i whit 'sudo apt install $i'"
		exit 1
	fi
	llvm_version=$(llvm-config --version)
done

# Set min required version of LLVM 
llvm_minreq=7

# Compare if installed version is newer than min required
if (( ${llvm_version%%.*} < $llvm_minreq )); then
	echo "Version of LLVM is too old. Need to be 7 or newer."
	exit 1
fi

if ! $(glxinfo | grep -q -e 'Mesa 18.2' -e 'Mesa 18.3' -e 'Mesa 18.4' -e 'Mesa 19' -e 'Mesa 20'); then
		echo "You must install at least Mesa 18.2.0"
		exit 1
fi

# Check if installation directory is set. otherwise will use default directory under .wine/Cemu 
if [ -z $1 ]; then instdir=$HOME/.wine/Cemu; else instdir=$HOME"$1"; fi


#*************
#* Installer *
#*************

# Get URL for Cemu and other downloads
cemurl=$(curl -s http://cemu.info |grep .zip |awk -F '"' {'print $2'})
# Commented since might be better use Cemu's graphics pack download 
# gpurl=$(curl -s https://github.com/slashiee/cemu_graphic_packs/releases |grep graphicPacks |awk -F '"' NR==1{'print $2'})
churl=$(curl -s https://cemuhook.sshnuke.net |grep .zip |awk -F '"' NR==2{'print $2'})
fonturl=https://github.com/dnmodder/cemu_lutris_files/raw/master/sharedFonts.tar.gz

# Get name of file which was downloaded
cemufile=$(basename "$cemurl")
#gpfile=$(basename "$gpurl")
chfile=$(basename "$churl")
fontfile=$(basename "$fonturl")

# Check if files are present, if not then download it
if [ ! -f "$cemufile" ]; then
	echo "Download latest '$cemufile'"
	wget -q --show-progress "$cemurl"
fi

#if [ ! -f "$gpfile" ]; then
#	echo "Download latest $gpfile"
#	wget -q --show-progress https://github.com$gpurl
#fi

if [ ! -f "$chfile" ]; then
	echo "Download latest '$chfile'"
	wget -q --show-progress "$churl"
fi

if [ ! -f "$fontfile" ]; then
	echo "Download latest '$fontfile'"
	wget -q --show-progress "$fonturl"
fi


# Create and configure wine prefix
echo "Configuring new wine prefix '$instdir'"
#export WINEPREFIX=$(realpath $instdir) 
#wineboot $instdir
#winetricks -q vcrun2015
#winetricks win7



# These are only for testing, will be deleted before release
echo "$cemufile"
#echo "$gpfile"
echo "$churl"
echo "$chfile"
echo "$fonturl"
echo "$fontfile"
echo "$llvm_version"

read -p "Press 'enter' to exit"


# Post install cleaning, will delete downloaded files
rm -rf "$cemufile"
rm -rf "$gpfile" 
rm -rf "$chfile"
rm -rf "$fontfile"

#**************************
#* Create launcher script *
#************************** 

cat > StartCemu.sh << EOF1

#!/bin/bash
export WINEPREFIX="$(realpath $instdir)"
#for cemuhook
export WINEDLLOVERRIDES="mscoree=;mshtml=;dbghelp.dll=n,b"

cd $(realpath $instdir)
mesa_glthread=true __GL_THREADED_OPTIMIZATIONS=1 vblank_mode=0 WINEESYNC=1 wine Cemu.exe "\$@"
EOF1
chmod +x StartCemu.sh
