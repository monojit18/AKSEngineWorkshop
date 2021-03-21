param([Parameter(Mandatory=$true)]  [string] $mode,
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-engine-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-engine-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-engine-workshop-kv",      
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6",
      [Parameter(Mandatory=$false)] [string] $nodePoolConfigFileName = "aks-engine-nodepool",
      [Parameter(Mandatory=$false)] [string] $nodepoolName = "akeiotpool",
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

if ($mode -eq "addpool")
{
      
      $deployCommand = "aks-engine addpool -m '$outputFolderPath/apimodel.json' -g $resourceGroup -l $location --client-id '$spAppId' --client-secret '$spPassword' -p '$templatesFolderPath/AKSEngine/$nodePoolConfigFileName.json'"
      Invoke-Expression -Command $deployCommand

}
elseif ($mode -eq "updpool")
{
      
      $updateCommand = "aks-engine update -m '$outputFolderPath/apimodel.json' -g $resourceGroup -l $location --client-id '$spAppId' --client-secret '$spPassword' --node-pool $nodepoolName"
      Invoke-Expression -Command $updateCommand

}

Write-Host "-----------Setup------------"