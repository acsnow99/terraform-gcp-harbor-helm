#run with -h flag to get info on this script

#only works on MacOS currently

#defaults
url="core.harbor.domain"
mainnet="default"
subnet="default"
clustername="harbor-kube"

unset name
#arguments passed in
while getopts ":hc:u:k:p:n:" opt; do
  case ${opt} in
   h )
     echo "Usage:
-n Name for the cluster
-u URL that will point to Harbor(no https:// at the beginning; example: core.harbor.domain)
-k Path to your gcloud service account key
-p ID of the project to deploy Harbor to
-n Network and subnetwork on GCP, separated by spaces" 1>&2
     exit 1
     ;;
   n )
     clustername=$OPTARG
     ;;
   u )
     url=$OPTARG
     ;;
   k )
     gkeypath=$OPTARG 
     ;;
   p )
     gproject=$OPTARG 
     ;;
   n )
     #loops through arguments that aren't prefaced by -, 
     #then adds them to an array after getopts to be split into the two vars
     network=("$OPTARG")
        until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
            network+=($(eval "echo \${$OPTIND}"))
            OPTIND=$((OPTIND + 1))
        done
     ;;
   \? )
     echo "Invalid Option: -$OPTARG
Usage:
-n Name for the cluster
-u URL that will point to Harbor(no https:// at the beginning; example: core.harbor.domain)
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
#array built from -n flag is split into these vars
mainnet="${network[0]}"
subnet="${network[1]}"


echo $mainnet
echo $subnet