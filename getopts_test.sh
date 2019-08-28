#!/bin/bash
# From https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/

gamemode="0"  # Default gamemode
worldname="k8s"  # Default worldname
version="1.14.4"
modname=""
modpack=""

# Parse options to the `mc-server` command
while getopts ":hg:w:v:m:f:" opt; do
  case ${opt} in
   h )
     echo "Usage:
-g Gamemode of the server(0 or 1)
-w Worldname of the server
-v Version of Minecraft to use
-m Activates Forge; path of mod required
-f Activates FTB; URL or path of modpack required
Note: Make sure the modpacks and mods match the version of Minecraft under the -v flag
Other Note: Use either -m or -f, not both at once" 1>&2
     exit 1
     ;;
   g )
     gamemode=$OPTARG 
     ;;
   w )
     worldname=$OPTARG 
     ;;
   v )
     version=$OPTARG
     ;;
   m )
     modded=true
     modname=$OPTARG
     ;;
   f )
     ftb=true
     modpack=$OPTARG
     ;;
   \? )
     echo "Invalid Option: -$OPTARG
Usage:
-g Gamemode of the server(0 or 1)
-w Worldname of the server
-v Version of Minecraft to use
-m Activates Forge; path of mod required
-f Activates FTB; URL or path of modpack required
Note: Make sure the modpacks and mods match the version of Minecraft under the -v flag
Other Note: Use either -m or -f, not both at once" 1>&2
     exit 1
     ;;
   : )
     echo "Invalid option: $OPTARG requires an argument" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))

if [ $modded ]
then
  echo "This command will create a Forge-modded version "${version}" world titled '"${worldname}"' with the "${modname}" mod installed. Continue(y or n)?"
  read run
  if [ $run = y ]
  then
    echo "Then here we go!"
  else
    echo "Server creation cancelled"
  fi
else 
  if [ $ftb ]
  then 
    echo "This command will create a FeedTheBeast version "${version}" world titled '"${worldname}"' with the modpack at 
"${modpack}" 
installed. Continue(y or n)?"
    read run
    if [ $run = y ]
    then
      echo "Then here we go!"
    else
      echo "Server creation cancelled"
    fi
  else 
    echo "This command will create a vanilla version "${version}" world titled '"${worldname}".' Continue(y or n)?"
    read run
    if [ $run = y ]
    then
      echo "Then here we go!"
    else
      echo "Server creation cancelled"
    fi
  fi
fi