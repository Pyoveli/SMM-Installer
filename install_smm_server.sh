#!/bin/bash

if (( $EUID == 0 )); then
	echo "Do not run as root."
	exit 1
fi

if [ -z "$DISPLAY" ]; then
	export DISPLAY=:0.0
fi

#Check if required software is installed
declare -a reqsw=("wine" "bsdtar" "unzip" "wget" "winetricks" "screen" "python3" "curl")
for i in "${reqsw[@]}"
do
	if ! [ -x "$(command -v $i)" ]; then
		echo "You must install $i"
		exit 1
	fi
done

#Set opts if unset
NEWLINE=$'\n'

if [[ "$winedir" == "" ]]; then
	winedir=$HOME/.wine/cemu
fi
if [[ "$instdir" == "" ]]; then
	instdir=$HOME/.wine/cemu/drive_c
fi
if [[ "$smmserverzip" == "" ]]; then
	smmserverfinal_v5=SmmServerFinal_v5.zip
fi
if [[ "$cemuhookzip" == "" ]]; then
	cemuhookzip=cemuhooktemp.zip
fi
if [[ "$gfxpackzip" == "" ]]; then
	gfxpackzip=gfxpacktemp.zip
fi

# Download files if missing
if [ ! -f "$smmserverfinal_v5" ]; then 
	echo "${NEWLINE}SmmServerFinal_v5.zip doesn't exist.${NEWLINE}Download and copy it to same folder whit this script from https://smmserver.github.io/"
	exit 1
fi
if [ ! -f "$cemuhookzip" ]; then
	echo "${NEWLINE}Downloading Cemuhook for Cemu"
	wget -q --show-progress -O cemuhooktemp.zip $(curl -s https://cemuhook.sshnuke.net |grep .zip |awk -F '"' NR==2{'print $2'})
fi
if [ ! -f "$gfxpackzip" ]; then
	echo "${NEWLINE}Downloading latest graphics packs"
	wget -q --show-progress -O gfxpacktemp.zip https://github.com$(curl https://github.com/slashiee/cemu_graphic_packs/releases |grep graphicPacks |awk -F '"' NR==1{'print $2'})
fi

# Install Caddy whit One-step installer script (bash)
#curl https://getcaddy.com | bash -s personal

#Configure wine prefix
echo "${NEWLINE}Configuring new wine prefix"
export WINEPREFIX=$(realpath $winedir) 
winetricks -q vcrun2015
winetricks win10

#Extract zips to right directories
echo "${NEWLINE}Extracting zips"
mkdir -p $instdir

if [ -f "$smmserverfinal_v5" ]; then
	bsdtar -xf "$smmserverfinal_v5" -s'|[^/]*/||' -C $instdir
fi
if [ -f "$cemuhookzip" ]; then
	unzip -q -o "$cemuhookzip" -d $instdir/Cemu
fi
if [ -f "$gfxpackzip" ]; then
	rm -rf ${instdir}/graphicPacks/* #remove old versions of Graphic Packs to help with major changes
	unzip -q -o "$gfxpackzip" -d ${instdir}/graphicPacks/
fi



#Create launch scripts
cat > LaunchSMMServer.sh << EOF1
#!/bin/bash
export WINEPREFIX="$(realpath $winedir)"
#for cemuhook
export WINEDLLOVERRIDES="mscoree=;mshtml=;dbghelp.dll=n,b"

# Make screen for SMM Server and direct output to NEX_SMM.log file
echo "Starting SMM Server..."
cd $(realpath $instdir/NintendoClients)
screen -dmS SMMServer python3 example_smm_server.py > $instdir/NEX_SMM.log

# Wait 2 second to make sure server has time to start
sleep 2

# Make screen for Friend Server and direct output to NEX_Friend.log file
echo "Srarting Friend Server..."
screen -dmS FServer python3 example_friend_server.py > $instdir/NEX_Friend.log


sleep 2s

echo Starting Pretendo++
cd $instdir/NintendoClients
nohup wine Pretendo++.exe > $instdir/Pretendo++.log &

echo "Now launching Caddy..."
cd $instdir/Caddy
ulimit -n 16384
screen caddy -conf $instdir/Caddy/Caddyfile 
#> $instdir/Caddy.log &
#screen nohup caddy -conf $instdir/Caddy/Caddyfile > $instdir/Caddy.log &
#-dmS caddy 

sleep 2s

# Start Cemu
# mesa_glthread=true __GL_THREADED_OPTIMIZATIONS=1 vblank_mode=0 WINEESYNC=1 
nohup wine $instdir/Cemu/Cemu.exe & 

read -p "When finished playing, Press enter to exit..."

sleep 1s

echo The End...

# Clear screems and Caddy
killall screen
killall caddy
EOF1
chmod +x LaunchSMMServer.sh

echo "${NEWLINE}Successfully installed to $(realpath $winedir)"
echo "You may now run CEMU whit SMM Server using LaunchSMMServer.sh written in this directory"
echo "You may place LaunchSMMServer.sh anywhere"
