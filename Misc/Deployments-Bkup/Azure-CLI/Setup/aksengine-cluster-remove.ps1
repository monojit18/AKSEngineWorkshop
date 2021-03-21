param([Parameter(Mandatory=$true)]  [string] $shouldRemoveSP = "false",
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-engine-workshop-rg",        
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-engine-workshop-cluster",       
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6")

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