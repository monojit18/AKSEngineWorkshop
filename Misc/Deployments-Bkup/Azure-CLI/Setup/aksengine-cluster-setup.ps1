param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-engine-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-engine-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-engine-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-engine-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-engine-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $clientAppID = "70dba699-0fba-4c1d-805e-213acea0a63e",
      [Parameter(Mandatory=$false)] [string] $serverAppID = "3adf37ca-d914-43e9-9b24-8c081e0b3a08",
      [Parameter(Mandatory=$false)] [string] $adminGroupID = "6ec3a0a8-a6c6-4cdf-a6e3-c296407a5ec1",
      [Parameter(Mandatory=$false)] [string] $tenantID = "3851f269-b22b-4de6-97d6-aa9fe60fe301",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitd/Materials/Projects/AKSProjects/AKSEngineWorkshop/Deployments") # As per host devops machine

$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"
$outputFolderPath = $templatesFolderPath + "/AKSEngine/Output/ClusterInfo"

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$kvShowAppIdCommand = "az keyvault secret show -n $aksSPIdName --vault-name $keyVaultName --query 'value' -o tsv"
$spAppId = Invoke-Expression -Command $kvShowAppIdCommand
if (!$spAppId)
{
      Write-Host "Error fetching Service Principal Id"
      return;
}

$kvShowSecretCommand = "az keyvault secret show -n $aksSPSecretName --vault-name $keyVaultName --query 'value' -o tsv"
$spPassword = Invoke-Expression -Command $kvShowSecretCommand
if (!$spPassword)
{
      Write-Host "Error fetching Service Principal Password"
      return;
}

$networkShowCommand = "az network vnet subnet show -n $aksSubnetName --vnet-name $aksVNetName -g $resourceGroup --query 'id' -o tsv"
$aksVnetSubnetId = Invoke-Expression -Command $networkShowCommand
if (!$aksVnetSubnetId)
{

      Write-Host "Error fetching Vnet"
      return;

}

$genericSetCommand = "--set masterProfile.dnsPrefix=$clusterName"
$aadSetCommand = ",aadProfile.clientAppID=$clientAppID,aadProfile.serverAppID=$serverAppID,aadProfile.adminGroupID=$adminGroupID,aadProfile.tenantID=$tenantID"
$vnetSubnetSetCommand = ",masterProfile.vnetSubnetId='$aksVnetSubnetId',agentPoolProfiles[0].vnetSubnetId='$aksVnetSubnetId',agentPoolProfiles[1].vnetSubnetId='$aksVnetSubnetId',agentPoolProfiles[2].vnetSubnetId='$aksVnetSubnetId'"
$parametersSetCommand = $genericSetCommand + $aadSetCommand + $vnetSubnetSetCommand
$deployCommand = "aks-engine deploy -m '$templatesFolderPath/AKSEngine/aks-engine-config.json' --azure-env 'AzurePublicCloud' -g $resourceGroup -l $location --client-id '$spAppId' --client-secret '$spPassword' $parametersSetCommand -o '$outputFolderPath' -f --auto-suffix"
Invoke-Expression -Command $deployCommand

Write-Host "-----------Setup------------"