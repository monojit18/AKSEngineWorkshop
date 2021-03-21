param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-engine-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-engine-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-engine-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-engine-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-engine-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $clientAppID = "<clientAppID>",
      [Parameter(Mandatory=$false)] [string] $serverAppID = "<serverAppID>",
      [Parameter(Mandatory=$false)] [string] $adminGroupID = "<adminGroupID>",
      [Parameter(Mandatory=$false)] [string] $tenantID = "<tenantID>",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<baseFolderPath>")  # Till Deployments

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