#!/bin/sh
#
# Change these for your account
#
X_DEPT="SA"
X_CUSTOMER="TEST"
X_PROJECT="Demo"
X_APPLICATION="DemoTest"
X_CONTACT="athatcher"
X_TTL="72"

PREFIX="alan7"
RESOURCE_TAGS="X-DEPT=${X_DEPT} X-CUSTOMER=${X_CUSTOMER} X-PROJECT=${X_PROJECT} X-APPLICATION=${X_APPLICATION} X-CONTACT=${X_CONTACT} X-TTL=${X_TTL}"
RESOURCE_GROUP="${PREFIX}-hab-aks-demo"
AKS_CLUSTER_NAME="${PREFIX}-aks-demo"
ACR_NAME="${PREFIX}habitatregistry"
LOCATION="eastus"

BLDR_PRINCIPAL_PASSWORD="ThisIsVeryStrongPassword"
AKS_VERSION="1.12.4"
#
# No Need to change these
#
BLDR_PRINCIPAL_NAME="${PREFIX}-habitat-acr-registry"
AKS_NODE_COUNT=3
ACR_SKU="Basic"

if [ ! -z ${UNIQUE_NAME} ]; then
    UNIQUE_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
    RESOURCE_GROUP="${RESOURCE_GROUP}-${UNIQUE_ID}"
    AKS_CLUSTER_NAME="aks-demo"
    ACR_NAME="${ACR_NAME}${UNIQUE_ID}"
    BLDR_PRINCIPAL_NAME="${BLDR_PRINCIPAL_NAME}-${UNIQUE_ID}"
fi
#
# Setup AKS
#
az group create --name $RESOURCE_GROUP --location ${LOCATION} --tags ${RESOURCE_TAGS}
az aks create --kubernetes-version ${AKS_VERSION} --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --node-count $AKS_NODE_COUNT --generate-ssh-keys --tags ${RESOURCE_TAGS}
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME

#
# Setup ACR
#
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku $ACR_SKU

#
# Grant Reader access to ACR from AKS
#
CLIENT_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)
az role assignment create --assignee $CLIENT_ID --role Reader --scope $ACR_ID

# Create Service Principal for Habitat Builder
OLD_ID=$(az ad sp list --spn http://${BLDR_PRINCIPAL_NAME} --query "[].appId" -o tsv)
if [ ! -z ${OLD_ID} ]; then
    az ad sp delete --id ${OLD_ID}
fi
az ad sp create-for-rbac --scopes $ACR_ID --role Owner --password "$BLDR_PRINCIPAL_PASSWORD" --name $BLDR_PRINCIPAL_NAME
BLDR_ID=$(az ad sp list --display-name $BLDR_PRINCIPAL_NAME  --query "[].appId" --output tsv)

echo "Configuration Details for Habitat Builder:"
echo "  Server URL : ${ACR_NAME}.azurecr.io"
echo "  Service Principal ID : $BLDR_ID"
echo "  Service Principal Password : $BLDR_PRINCIPAL_PASSWORD"