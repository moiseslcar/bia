./build.sh
aws ecs update-service --cluster bia --service service-bia --force-new-deployment
