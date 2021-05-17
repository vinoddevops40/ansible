#!/bin/bash

LID=lt-0da1fb56f241b319b
LVER=2
#COMPONENT=$1

#if [ -z "${COMPONENT}" ]; then
#  echo "Component Name Input Needed"
#  exit 1
#fi


Instance_Create() {
COMPONENT=$1
##aws ec2 run-instances  --launch-template LaunchTemplateId=${LID},Version=${LVER}  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}}]" | jq
INSTANCE_EXIST=$(aws ec2 describe-instances --filters Name=tag:Name,Values=${COMPONENT} | jq .Reservations[])
STATE=$(aws ec2 describe-instances --filters Name=tag:Name,Values=user | jq .Reservations[].Instances[].State.Name | xargs)

if [ -z "${INSTANCE_EXIST}"  -o "$STATE" == "terminated" ]; then

    aws ec2 run-instances  --launch-template LaunchTemplateId=${LID},Version=${LVER}  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}}]" | jq
else
  echo "Instance ${COMPONENT} already exist"

fi

IPADDRESS=$(aws ec2 describe-instances --filters Name=tag:Name,Values=${COMPONENT} | jq .Reservations[].Instances[].PrivateIpAddress | grep -v null | xargs)
sed -e "s/COMPONENT/${COMPONENT}/" -e "s/IPADDRESS/${IPADDRESS}/" record.json >/tmp/record.json
aws route53 change-resource-record-sets --hosted-zone-id Z0119149I8S0IAPXEMO8 --change-batch file:///tmp/record.json

echo "${IPADDRESS} APP=${COMPONENT}" >>../inventory

}

if [ "$1" == "all" ]; then
  for instance in frontend mongodb catalogue redis user cart mysql shipping rabbitmq payment ; do
    Instance_Create $instance
  done
else
  Instance_Create $1
fi
