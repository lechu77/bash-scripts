# VPC
Scripts used for VPC creation

# vpc_create.sh
# create_vpc.sh by Lechu (matias *AT* lechu.com.ar)
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

