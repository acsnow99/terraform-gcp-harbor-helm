#make sure to run with sudo

#defaults
mainnet="default"
subnet="default"

#arguments passed in
while getopts ":hk:p:n:" opt; do
  case ${opt} in
   h )
     echo "Usage:
-k Path to your gcloud service account key
-p ID of the project to deploy Harbor to
-n Network and subnetwork on GCP, separated by spaces" 1>&2 1>&2
     exit 1
     ;;
   k )
     gkeypath=$OPTARG 
     ;;
   p )
     gproject=$OPTARG 
     ;;
   n )
     network=("$OPTARG")
        until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
            network+=($(eval "echo \${$OPTIND}"))
            OPTIND=$((OPTIND + 1))
        done
     ;;
   \? )
     echo "Invalid Option: -$OPTARG
Usage:
-k Path to your GCP service account key
-p ID of the GCP project to deploy Harbor to
-n Network and subnetwork on GCP, separated by spaces" 1>&2
     exit 1
     ;;
   : )
     echo "Invalid option: $OPTARG requires an argument" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))
mainnet="${network[0]}"
subnet="${network[1]}"

echo $gkeypath
echo $gproject
echo $mainnet
echo $subnet