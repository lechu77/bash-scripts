#!/bin/bash

#######################################################################################################
#
# create_vpc.sh by Lechu (matias@lechu.com.ar)
# Complete next VARS in order to execute this 
# script. This is very alpha, so feel free to
# Include a few "if" or "case" to check or use
# these from command line: $1 $2 $N
# 
# TMPFILE= File to use to store temp data (Es: /tmp/create_vpc.out)
# ZONE= AWS Region in AZ form (Ex: us-east-1)
# VPCNET= Network used to create all network objects (Ex: 172.16 - do *not* include las two octets)
# NCONV= Naming convention to use on each object created (Ex: VPC-TEST)
# SGTAG= Same as NCONV, used for the Security Groups (Usually $NCONV)
#
# Please note that AWS CLI has to be configured before running this script ($ aws configure)
# 
#######################################################################################################

export TMPFILE=/tmp/vpctemp.out
export ZONE=us-east-1
export VPCNET=172.16
export NCONV=MyVPC-TEST
export SGTAG=$NCONV

### ### ### DEFAULT VPC ### ### ###
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" > $TMPFILE
cat $TMPFILE
export VPCID=`cat $TMPFILE | grep VpcId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 create-tags --resources $VPCID --tags 'Key="Name",Value="DO *NOT* USE - DEFAULT VPC"'

### ### ### NEW VPC ### ### ###
aws ec2 create-vpc --cidr-block $VPCNET.0.0/16 > $TMPFILE
cat $TMPFILE
export VPCID=`cat $TMPFILE | grep VpcId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 modify-vpc-attribute --vpc-id $VPCID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPCID --enable-dns-hostnames "{\"Value\":true}"
aws ec2 create-tags --resources $VPCID --tags "Key="Name",Value='$NCONV'"


### ### ### IGW ### ### ###
aws ec2 create-internet-gateway > $TMPFILE
cat $TMPFILE
export IGWID=`cat $TMPFILE | grep InternetGatewayId| awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 attach-internet-gateway --internet-gateway-id $IGWID --vpc-id $VPCID
aws ec2 create-tags --resources $IGWID --tags 'Key="Name",Value='$NCONV' - IGW'

################################
### ### ### PUB SUBNETS ### ### ###
### ROUTE TB ###
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" > $TMPFILE
cat $TMPFILE
export RTBID=`cat $TMPFILE | grep -A1 '"Main": true' | grep RouteTableId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 create-route --route-table-id $RTBID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGWID
aws ec2 create-tags --resources $RTBID --tags 'Key="Name",Value='$NCONV' RT - Main Public'

### 1st DMZ SUBNET ###
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $VPCNET.11.0/24 --availability-zone "$ZONE"a  > $TMPFILE
cat $TMPFILE
export SN11ID=`cat $TMPFILE | grep SubnetId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 associate-route-table --route-table-id $RTBID --subnet-id "$SN11ID"
aws ec2 create-tags --resources $SN11ID --tags 'Key="Name",Value='$NCONV' DMZ - '$VPCNET'.11.x '$ZONE'a'

### 2nd DMZ SUBNET ###
aws ec2 create-subnet --vpc-id $VPCID --cidr-block  $VPCNET.22.0/24 --availability-zone "$ZONE"b > $TMPFILE
cat $TMPFILE
export SN22ID=`cat $TMPFILE | grep SubnetId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 associate-route-table --route-table-id $RTBID --subnet-id "$SN22ID"
aws ec2 associate-route-table --route-table-id $RTBID --subnet-id "$SN22ID"
aws ec2 create-tags --resources $SN22ID --tags 'Key="Name",Value='$NCONV' DMZ - '$VPCNET'.22.x '$ZONE'b'

### 3rd DMZ SUBNET ###
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $VPCNET.33.0/24 --availability-zone "$ZONE"c > $TMPFILE
cat $TMPFILE
export SN33ID=`cat $TMPFILE | grep SubnetId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 associate-route-table --route-table-id $RTBID --subnet-id "$SN33ID"
aws ec2 create-tags --resources $SN33ID --tags 'Key="Name",Value='$NCONV' DMZ - '$VPCNET'.33.x '$ZONE'c'


### ## ### PRIV SUBNETS ### ### ###
aws ec2 create-route-table --vpc-id $VPCID > $TMPFILE
cat $TMPFILE
export RTPID=`cat $TMPFILE | grep RouteTableId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 create-tags --resources $RTPID --tags 'Key="Name",Value='$NCONV' RT - NAT Private'

### 1st INT SUBNET ###
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $VPCNET.1.0/24 --availability-zone "$ZONE"a > $TMPFILE
cat $TMPFILE
export SN1ID=`cat $TMPFILE | grep SubnetId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 associate-route-table --route-table-id $RTPID --subnet-id $SN1ID
aws ec2 create-tags --resources $SN1ID --tags 'Key="Name",Value='$NCONV' INT - '$VPCNET'.1.x '$ZONE'a'

### 2nd INT SUBNET ###
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $VPCNET.2.0/24 --availability-zone "$ZONE"b> $TMPFILE
export SN2ID=`cat $TMPFILE | grep SubnetId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 associate-route-table --route-table-id $RTPID --subnet-id $SN2ID
aws ec2 create-tags --resources $SN2ID --tags 'Key="Name",Value='$NCONV' INT - '$VPCNET'.2.x '$ZONE'b'

### 3rd INT SUBNET ###
aws ec2 create-subnet --vpc-id $VPCID --cidr-block $VPCNET.3.0/24 --availability-zone "$ZONE"c > $TMPFILE
export SN3ID=`cat $TMPFILE | grep SubnetId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
aws ec2 associate-route-table --route-table-id $RTPID --subnet-id $SN3ID
aws ec2 create-tags --resources $SN3ID --tags 'Key="Name",Value='$NCONV' INT - '$VPCNET'.3.x '$ZONE'c'


### ### ### SECURITY GROUPS ### ### ###
### MISC ###
aws ec2 create-security-group --group-name "$SGTAG - SG - MISC" --description "$SGTAG Security Group for Miscellaneous traffic" --vpc-id $VPCID > $TMPFILE
export GRPMISC=`cat $TMPFILE | grep GroupId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`

aws ec2 authorize-security-group-ingress --group-id "$GRPMISC" --ip-permissions '[{"IpProtocol": "-1", "FromPort": 0, "ToPort": 65535, "IpRanges": [{"CidrIp": "'$VPCNET'.0.0/16"}]}]'


### RA ###
aws ec2 create-security-group --group-name "$SGTAG - SG - RA" --description "$SGTAG Security Group for Remote Access" --vpc-id $VPCID  > $TMPFILE
export GRPRA=`cat $TMPFILE | grep GroupId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`

aws ec2 authorize-security-group-ingress --group-id "$GRPRA" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

aws ec2 revoke-security-group-egress --group-id "$GRPRA" --ip-permissions '[{"IpProtocol": "-1", "FromPort": -1, "ToPort": -1, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

### VPN ###
aws ec2 create-security-group --group-name "$SGTAG - SG - VPN" --description "$SGTAG Security Group for VPN Access" --vpc-id $VPCID > $TMPFILE
export GRPVPN=`cat $TMPFILE | grep GroupId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`
 
aws ec2 authorize-security-group-ingress --group-id "$GRPVPN" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 1723, "ToPort": 1723, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
 
aws ec2 authorize-security-group-ingress --group-id "$GRPVPN" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 443, "ToPort": 443, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
 
aws ec2 authorize-security-group-ingress --group-id "$GRPVPN" --ip-permissions '[{"IpProtocol": "udp", "FromPort": 500, "ToPort": 500, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
 
aws ec2 authorize-security-group-ingress --group-id "$GRPVPN" --ip-permissions '[{"IpProtocol": "udp", "FromPort": 4500, "ToPort": 4500, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
 
aws ec2 authorize-security-group-ingress --group-id "$GRPVPN" --ip-permissions '[{"IpProtocol": "udp", "FromPort": 1701, "ToPort": 1701, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
 
aws ec2 revoke-security-group-egress --group-id "$GRPVPN" --ip-permissions '[{"IpProtocol": "-1", "FromPort": -1, "ToPort": -1, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'




### WEB ###
aws ec2 create-security-group --group-name "$SGTAG - SG - WEB" --description "$SGTAG Security Group for WEB" --vpc-id $VPCID  > $TMPFILE
export GRPWEB=`cat $TMPFILE | grep GroupId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`

aws ec2 authorize-security-group-ingress --group-id "$GRPWEB" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
aws ec2 authorize-security-group-ingress --group-id "$GRPWEB" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 8080, "ToPort": 8080, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
aws ec2 authorize-security-group-ingress --group-id "$GRPWEB" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 443, "ToPort": 443, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
aws ec2 authorize-security-group-ingress --group-id "$GRPWEB" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 8443, "ToPort": 8443, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

aws ec2 revoke-security-group-egress --group-id "$GRPWEB" --ip-permissions '[{"IpProtocol": "-1", "FromPort": -1, "ToPort": -1, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

### DB ###
aws ec2 create-security-group --group-name "$SGTAG - SG - DB" --description "$SGTAG Security Group for Database" --vpc-id $VPCID > $TMPFILE
export GRPDB=`cat $TMPFILE | grep GroupId | awk -F": " '{print $NF}' | awk -F'"' '{print $2}'`

### MySQL/MariaDB ###
aws ec2 authorize-security-group-ingress --group-id "$GRPDB" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 3306, "ToPort": 3306, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

### MS SQL ###
aws ec2 authorize-security-group-ingress --group-id "$GRPDB" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 1433, "ToPort": 1433, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

### PostgreSQL ###
aws ec2 authorize-security-group-ingress --group-id "$GRPDB" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 5432, "ToPort": 5432, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

aws ec2 revoke-security-group-egress --group-id "$GRPDB" --ip-permissions '[{"IpProtocol": "-1", "FromPort": -1, "ToPort": -1, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'


# Launch Amazon Linux 2017.03.1 - us-east-1
AMI=ami-4fffc834
KEY="SYSTAR-us-east-1"
SGRA="sg-22412e51"
SGMISC="sg-a75b34d4"
SUBNET11="subnet-69556733"
# aws ec2 run-instances --image-id $AMI --count 1 --instance-type t2.nano --key-name $KEY --security-group-ids $SGRA $SGMISC --subnet-id $SUBNET11
# aws ec2 create-tags --resources i-0f67c22f367f7e006 --tags 'Key="Name",Value='$NCONV'-FW-NAT

