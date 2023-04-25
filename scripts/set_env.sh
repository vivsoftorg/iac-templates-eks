#! /bin/bash
ENVRC=$1
touch $ENVRC
source $ENVRC

if [ -z ${AWS_ACCESS_KEY_ID+x} ]; then
    echo "AWS_ACCESS_KEY_ID is unset"
    read -p "Enter the AWS_ACCESS_KEY_ID to set for Terragrunt : " AWS_ACCESS_KEY_ID
    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
    echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >>$ENVRC
else
    echo "AWS_ACCESS_KEY_ID is already set."
fi

if [ -z ${AWS_SECRET_ACCESS_KEY+x} ]; then
    echo "AWS_SECRET_ACCESS_KEY is unset"
    read -p "Enter the AWS_SECRET_ACCESS_KEY to set for Terragrunt : " AWS_SECRET_ACCESS_KEY
    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
    echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >>$ENVRC
else
    echo "AWS_SECRET_ACCESS_KEY is already set."
fi

if [ -z ${AWS_DEFAULT_REGION+x} ]; then
    echo "AWS_DEFAULT_REGION is unset"
    read -p "Enter the AWS_DEFAULT_REGION to set : " REGION
    export AWS_DEFAULT_REGION=$REGION
    echo "export AWS_DEFAULT_REGION=$REGION" >>$ENVRC
else
    echo "AWS_DEFAULT_REGION is already set"
fi

source $ENVRC
