#!/bin/sh
$LOCATION="westeurope"
az deployment sub create -l westeurope --template-file .\01_resource_group.json
cls


az deployment group create -g anbossar-arm-demo --template-file .\02_aks.json --mode Complete
az deployment group create -g anbossar-arm-demo --template-file .\03_cleanup.json --mode Complete

az deployment group create -g anbossar-arm-demo --template-file .\02_kv_appservice_storage.json --mode Complete

az group create --name mygroup --location westeurope

