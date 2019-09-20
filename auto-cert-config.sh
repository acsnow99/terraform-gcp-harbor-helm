while getopts ":hu:" opt; do
  case ${opt} in
  h )
    echo "Usage:
-u: URL of your Harbor deployment"
    ;;
  u )
    url=$OPTARG
    ;;
   \? )
     echo "Invalid Option: -$OPTARG
Usage:
-u: URL of your Harbor deployment" 1>&2
     exit 1
     ;;
   : )
     echo "Invalid option: $OPTARG requires an argument" 1>&2
     exit 1
     ;;
  esac
done

if [ $OPTIND -eq 1 ]
then
   echo "Error: No arguments passed
Usage:
-u: URL of your Harbor deployment"
   exit
fi

curl -k -o ca.crt https://$url/api/systeminfo/getcert
sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db ca.crt
# restart Docker
killall Docker && open /Applications/Docker.app

sleep 60

# login to docker and push a test image
sudo docker login --username admin --password Harbor12345 $url
sudo docker tag hello-world:latest $url/library/hello-world:latest
sudo docker push $url/library/hello-world:latest