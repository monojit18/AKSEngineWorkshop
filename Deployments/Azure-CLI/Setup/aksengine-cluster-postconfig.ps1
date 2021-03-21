param([parameter(Mandatory=$false)] [string] $resourceGroup = "aks-engine-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $projectName = "aks-engine-workshop",
      [Parameter(Mandatory=$false)] [string] $appgwName = "aks-engine-workshop-appgw",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-engine-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-engine-workshop-appgw-subnet",
      [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName = "aksengine-appgw-deploy",
      [Parameter(Mandatory=$false)] [string] $ingControllerIPAddress = "193.0.0.200",
      [Parameter(Mandatory=$false)] [string] $ingHostName = "<ingressHostName>",
      [Parameter(Mandatory=$false)] [string] $listenerHostName = "<listenerHostName>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<baseFolderPath>") # Till Deployments

$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"
$ingControllerName = $projectName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$ingControllerFilePath = "$yamlFilePath/Common/$ingControllerFileName.yaml"

# Configure ILB file
$ingressContent = Get-Content -Path $ingControllerFilePath -Raw
$ingressContent = $ingressContent -replace "<PRIVATE_IP>", $ingControllerIPAddress
Set-Content -Path $ingControllerFilePath  $ingressContent

# Create nginx Namespace
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$nginxRepoAddCommand = "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
Invoke-Expression -Command $nginxRepoAddCommand

$nginxRepoUpdateCommand = "helm repo update"
Invoke-Expression -Command $nginxRepoUpdateCommand

$nginxILBCommand = "helm install $ingControllerName ingress-nginx/ingress-nginx --namespace $ingControllerNSName -f $yamlFilePath/Common/$ingControllerFileName.yaml"
Invoke-Expression -Command $nginxILBCommand

# Install AppGW
$appgwParameters = "applicationGatewayName=$appgwName projectName=$projectName vnetName=$aksVNetName subnetName=$appgwSubnetName backendIpAddress1=$ingControllerIPAddress backendPoolHostName=$ingHostName listenerHostName=$listenerHostName"
$appgwDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/AppGW/$appgwTemplateFileName.json --parameters $templatesFolderPath/AppGW/$appgwTemplateFileName.parameters.json --parameters $appgwParameters --query='id' -o json"
Invoke-Expression -Command $appgwDeployCommand

Write-Host "-----------Post-Config------------"
