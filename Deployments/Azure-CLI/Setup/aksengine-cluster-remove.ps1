param([Parameter(Mandatory=$true)]  [string] $shouldRemoveSP = "false",
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-engine-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-engine-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscriptionId>")

$aksSPName = $clusterName + "-sp"
$subscriptionCommand = "az account set -s $subscriptionId"

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

# Delete Resource Group
az group delete -g $resourceGroup --yes

if ($shouldRemoveSP -eq "true")
{

      $spDeleteCommand = "az ad sp delete --id http://$aksSPName"
      Invoke-Expression -Command $spDeleteCommand
        
}

Write-Host "-----------Remove------------"