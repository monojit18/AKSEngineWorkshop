param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-engine-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-engine-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $acrName = "aksengnacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-engine-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-engine-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksVNetPrefix = "193.0.0.0/16",      
      [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-engine-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $aksSubnetPrefix = "193.0.0.0/23",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-engine-workshop-appgw-subnet",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix = "193.0.2.0/24",
      [Parameter(Mandatory=$false)] [string] $appgwName = "aks-engine-workshop-appgw",
      [Parameter(Mandatory=$false)] [string] $networkTemplateFileName = "aksengine-network-deploy",
      [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "aksengine-acr-deploy",
      [Parameter(Mandatory=$false)] [string] $kvTemplateFileName = "aksengine-keyvault-deploy",
      [Parameter(Mandatory=$false)] [string] $pfxCertFileName = "star.wkshpdev.com",
      [Parameter(Mandatory=$false)] [string] $rootCertFileName = "star_internal_wkshpdev_com_116401008TrustedRoot",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6",
      [Parameter(Mandatory=$false)] [string] $objectId = "890c52c5-d318-4185-a548-e07827190ff6",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitd/Materials/Projects/AKSProjects/AKSEngineWorkshop/Deployments") # Till Deployments

$vnetRole = "'Network Contributor'"
$aksSPDisplayName = $clusterName + "-sp"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"

$certSecretName = $appgwName + "-cert-secret"
$certPFXFilePath = $baseFolderPath + "/Certs/$pfxCertFileName.pfx"

$rootCertSecretName = $appgwName + "-root-cert-secret"
$certCERFilePath = $baseFolderPath + "/Certs/$rootCertFileName.cer"

# Assuming Logged In

$rgShowCommand = "az group show --name $resourceGroup --subscription $subscriptionId --query 'id' -o json"
$rgCreateCommand = "az group create --name $resourceGroup -l $location --subscription $subscriptionId --query='id'"

$networkShowCommand = "az network vnet show -n $aksVNetName -g $resourceGroup --query 'id' -o json"
$networkNames = "aksVNetName=$aksVNetName aksVNetPrefix=$aksVNetPrefix aksSubnetName=$aksSubnetName aksSubnetPrefix=$aksSubnetPrefix appgwSubnetName=$appgwSubnetName appgwSubnetPrefix=$appgwSubnetPrefix"
$networkDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/Network/$networkTemplateFileName.json --parameters $networkNames"

$acrShowCommand = "az acr show -n $acrName --query 'id' -o json"
$acrDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/ACR/$acrTemplateFileName.json --parameters acrName=$acrName"

$keyVaultShowCommand = "az keyvault show -n $keyVaultName --query 'id' -o json"
$keyVaultDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/KeyVault/$kvTemplateFileName.json --parameters keyVaultName=$keyVaultName objectId=$objectId"

$spShowCommand = "az ad sp show --id http://$aksSPDisplayName --query 'appId'"
$spCreateCommand = "az ad sp create-for-rbac --skip-assignment --name $aksSPDisplayName --query '{appId:appId, secret:password}' -o json"

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$rgRef = Invoke-Expression -Command $rgShowCommand
if (!$rgRef)
{
   $rgRef = Invoke-Expression -Command $rgCreateCommand
   if (!$rgRef)
   {
        Write-Host "Error creating Resource Group"
        return;
   }

   Write-Host $rgRef

}

$aksVnet = Invoke-Expression -Command $networkShowCommand
if (!$aksVnet)
{

    Invoke-Expression -Command $networkDeployCommand
    $aksVnet = Invoke-Expression -Command $networkShowCommand
    Write-Host $aksVnet

}

$acrInfo = Invoke-Expression -Command $acrShowCommand
if (!$acrInfo)
{
    
    Invoke-Expression -Command $acrDeployCommand
    $acrInfo = Invoke-Expression -Command $acrShowCommand
    Write-Host $acrInfo

}

$keyVaultInfo = Invoke-Expression -Command $keyVaultShowCommand
if (!$keyVaultInfo)
{

    Invoke-Expression -Command $keyVaultDeployCommand
    $keyVaultInfo = Invoke-Expression -Command $keyVaultShowCommand
    Write-Host $keyVaultInfo

}

$aksSP = Invoke-Expression -Command $spShowCommand
if (!$aksSP)
{
    $aksSP = Invoke-Expression -Command $spCreateCommand
    if (!$aksSP)
    {

        Write-Host "Error creating Service Principal for AKS"
        return;

    }

    $appId = ($aksSP | ConvertFrom-Json).appId
    $secret = ($aksSP | ConvertFrom-Json).secret

    $kvShowAppIdCommand = "az keyvault secret show -n $aksSPIdName --vault-name $keyVaultName --query 'id' -o json"
    $kvAppIdInfo = Invoke-Expression -Command $kvShowAppIdCommand
    if (!$kvAppIdInfo)
    {
        $kvSetAppIdCommand = "az keyvault secret set --vault-name $keyVaultName --name $aksSPIdName --value $appId"
        Invoke-Expression -Command $kvSetAppIdCommand
    }

    $kvShowSecretCommand = "az keyvault secret show -n $aksSPSecretName --vault-name $keyVaultName --query 'id' -o json"
    $kvSecretInfo = Invoke-Expression -Command $kvShowSecretCommand
    if (!$kvSecretInfo)
    {
        $kvSetSecretCommand = "az keyvault secret set --vault-name $keyVaultName --name $aksSPSecretName --value $secret"
        Invoke-Expression -Command $kvSetSecretCommand
    }

    $networkRoleCommand = "az role assignment create --assignee $appId --role $vnetRole --scope $aksVnet"
    Invoke-Expression -Command $networkRoleCommand

    $acrRoleCommand = "az role assignment create --assignee $appId --role 'AcrPush' --scope $acrInfo"
    Invoke-Expression -Command $acrRoleCommand

    $resourceGroupRoleCommand = "az role assignment create --assignee $appId --role 'Owner' --scope '/subscriptions/$subscriptionId/resourceGroups/$resourceGroup'"
    Invoke-Expression -Command $resourceGroupRoleCommand

}

$certPFXBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certPFXContents = [Convert]::ToBase64String($certPFXBytes)

$certCERBytes = [System.IO.File]::ReadAllBytes($certCERFilePath)
$certCERContents = [Convert]::ToBase64String($certCERBytes)

$kvShowPFXCommand = "az keyvault secret show -n $certSecretName --vault-name $keyVaultName --query 'id' -o json"
$kvPFXInfo = Invoke-Expression -Command $kvShowPFXCommand
if (!$kvPFXInfo)
{
    $kvSetPFXCommand = "az keyvault secret set --name $certSecretName --vault-name $keyVaultName --value $certPFXContents --query 'name' -o json"
    Invoke-Expression -Command $kvSetPFXCommand
}

$kvShowCERCommand = "az keyvault secret show -n $rootCertSecretName --vault-name $keyVaultName --query 'id' -o json"
$kvCERInfo = Invoke-Expression -Command $kvShowCERCommand
if (!$kvCERInfo)
{
    $kvSetCERCommand = "az keyvault secret set --name $rootCertSecretName --vault-name $keyVaultName --value $certCERContents --query 'name' -o json"
    Invoke-Expression -Command $kvSetCERCommand
}

Write-Host "------------Pre-Config----------"
