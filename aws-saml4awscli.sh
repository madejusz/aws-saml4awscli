#!/bin/bash

# Copyright by Jakub K. Boguslaw <jboguslaw@gmail.com>
#
# Requirments:
# jq
# awscli version 2

if ! jq --version &>/dev/null ; then
	echo "jq is missing"
	exit 128
fi
if ! aws --version &>/dev/null; then
	echo "aws cli is missing"
	exit 128
fi
jq --version
aws --version
#
if [ $# -ne 4 ]; then
	echo "$0 accountname accoutnumber provider role_name"
	exit 0
fi

ACCOUNTNAME="$1"
ACCOUNTNUMBER=$2
PROVIDER=$3
ROLE_NAME=$4

AWS_PROFILE="${ACCOUNTNAME}-sso"

export AWS_PAGER=""

if [ ! -f "samlresponse.log" ]; then
	echo "Open chrome browser -> More tools -> development tools"
	echo "Go to: https://example.com/adfs/ls/idpinitiatedsignon.aspx?loginToRP=urn:amazon:webservices"
	echo "In network->Headers find POST with SAMLResponse, and write content of header into samlresponse.log file"
	echo "After that, run this script"
fi


read accesskeyid secretaccesskey sessiontoken expiration <<<$(echo $(aws sts assume-role-with-saml \
	--role-arn arn:aws:iam::${ACCOUNTNUMBER}:role/${ROLE_NAME} \
	--principal-arn arn:aws:iam::${ACCOUNTNUMBER}:saml-provider/${PROVIDER} \
	--saml-assertion file://${HOME}/tmp/samlresponse.log | \
	jq '.Credentials | (.AccessKeyId, .SecretAccessKey, .SessionToken, .Expiration)' | \
       	tr -d '"'))

if [ "$accesskeyid" == "" ]; then 
	echo "ERROR!"
	exit 128
fi

echo "Expiration: $expiration"
#echo accesskeyid=$accesskeyid
#echo secretaccesskey=$secretaccesskey
#echo sessiontoken=$sessiontoken
aws configure --profile $AWS_PROFILE set aws_access_key_id $accesskeyid 
aws configure --profile $AWS_PROFILE set aws_secret_access_key $secretaccesskey 
aws configure --profile $AWS_PROFILE set aws_session_token $sessiontoken

echo "AWS PROFILE: $AWS_PROFILE"
aws --profile $AWS_PROFILE sts get-caller-identity
# eof
