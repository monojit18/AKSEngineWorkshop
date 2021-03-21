# Kubernetes on Azure - Dissect AKS-Engine



## Prelude

### AKS-Engine

### Units of Kubernetes on Azure!

This is how AKS-Engine is described in a nutshell - one that provides ingredients to build to your own vanilla K8s cluster on Azure VMs.

This is also forms the foundation for Microsoft's flagship product for managed Kubernetes on Azure cloud - a.k.a *AKS*. Although there are more popular and community supported open source tools available to have a vanilla cluster anywhere - e.g. *Cluster API Provider* a.k.a *CAPZ*. And as it seems this is going to be the de-facto tool for cluster deployment on any cloud or on-prem.

While the above options are all good for *Managed* scenarios, how to meet the customer requirements on deploying K8s on VMs on Azure and let them manage end-to-end? While customers can use *CAPZ* or the most popular, standard tools like ***kubeadm*** can be used to spin-off a cluster; the other option we have now is the **AKS-Engine** - which provides a set of templates for deployingvanilla K8s cluster pod Azure Infrastructure easily and quickly; without going thru the much complexities of K8s internals.

Without much prelude, let us get into some action.

But K8s cluster is not the only thing that user(s) are going to create; rather the ancillary services around the cluster helping build the entire architecture is most important, painfully redundant and difficult to manage in long terms - more so when you think of the Operations team or Infrastructure management team - who might need to do this for multiple cluster to be managed and many applications to be deployed!

Hence a *Disciplined, Streamlined* and *Automated* approach is needed so that end to end architecture becomes *Robust*, *Resilient* and easily *Manageable*.

The purpose of this workshop would be to:

- Use Kubernetes as the tool for orchestration of micro-services
- Build micro-services of varying nature and tech-stack
- Build an automated pipeline and workflow for creating Infrastructure for the deploying micro-services - *3-Step Approach*
- Use AKS-engine templates for creating the Core K8s infrastructure
- Use ARM templates to deploy other ancillary Azure resources
- Extend the pipeline to automate deployment of micro-services
- Use the built-in features of K8s for monitoring, security and upgrades
- Define Resource Quota and appropriate Storage for micro-services
- Integrating with Azure AD and define RBAC for the cluster and its sub-components

### Pre-requisites, Assumptions

- Knowledge on Containers and MicroServices - *L300+*

- How to build docker image and create containers from it

- Knowledge on K8s  - *L300+*

- Some knowledge on Azure tools & services viz. *Azure CLI, KeyVault, VNET* etc. would help

- Apps and Micro-Services would be used interchangeably i.e. both are treated as same in this context

  

## Reference Architecture

![ASH-Ref-Architecture-v1.0-Stack-Hub-Ref-Arch](./Assets/ASH-Ref-Architecture-v1.0-Stack-Hub-Ref-Arch.png)

## Action

Let us now get into some action with all *Plans* in-place!

As we had mentioned, it would be a 3-step approach to create the cluster. We would first do this with scripts from command line and then would do the same using Azure DevOps. Once the cluster is ready, we can start deploying applications onto it. Let us set the ball rolling...

Before getting into actual action, couple of minutes to understand the folder structure that we would be following (*most important*). 

### Deployments

- **Certs** - Contains all certificates needed; in this case basically the SSL certificate for Ingress controller

  (*Note*: *This folder is not checked into the repo; please create this folder on your local system and necessary certificates*)

- **Azure-CLI** - Contains all necessary files for azure cli scripts to be used for deployment. For folks want to do in Terraform way should create a similar folder and the appropriate files inside

  - **Setup** - Contains all the scripts to be used in this process

    (***Ref***: *Deployments/Azure-CLI/Setup*)

  - **Templates** - The key folder which contains all ARM templates and corresponding PowerShell scripts to deploy them. This ensures a completely decoupled approach for deployment; all ancillary components can be deployed outside the cluster process at any point of time!

    (***Ref***: ***Deployments/Azure-CLI/Templates***)

- **YAMLs** - Contains all YAML files needed post creation of cluster - Post Provisioning stage where created cluster is configured by Cluster Admins

  (***Ref***: ***Deployments/YAMLs***)

  - **ClusterAdmin** - Scripts for Cluster Admin functionalities

    (*Ref*: ***Deployments/YAMLs/ClusterAdmin***)

  - **Common** - Scripts used across different namespaces - e.g. *nginx ingress* configuration file

    (*Ref*: ***Deployments/YAMLs/Common***)

  - **Ingress** - Scripts for Ingress creation for the DEV namespace

    (*Ref*: ***Deployments/YAMLs/DEV/Ingress***)

  - **Monitoring** - Scripts for Container Monitoring for entire cluster. For this workshop it includes the Prometheus config map which would allow Prometheus to scrape data from specific Pods, Services

    (*Ref*: ***Deployments/YAMLs/DEV/Monitoring***)
    
  - **Netpol** - Scripts for defining network policies between Pods, Services as well as outbound from Pods
  
    (*Ref*: ***Deployments/YAMLs/DEV/Netpol***)
  
  - **RBAC** - Scripts for defining RBAC between various resources within K8s cluster
  
    (*Ref*: ***Deployments/YAMLs/DEV/RBAC***)



## Anatomy of the Approach



### Step-By-Step

3. **Create** a *Management Resource Group*, say, **aks-mgmt-rg**

2. **Create** VNet and SubNet for Jump Server VM

5. **Create** a Jump Server VM - preferred is Windows VM so that all visualisation tools like **Lens** etc. can be used to view the cluster status at runtime. The one used for this workshop was - 

   - OS - **Windows Server 2019 DC - v1809**
   - Size  - **Standard DS2 v2 (2 vcpus, 7 GiB memory)**

6. **RDP** to the windows VM

7. **Install** following tools for creation and management of the cluster and its associated resources

   1. **Chocolatey**

      ```bash
      # Follow this link and install Chocolatey latest
      https://chocolatey.org/install
      ```

   2. **Azure CLI**

      ```bash
      # Follow this link and install Azure CLI latest
      https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli
      ```

   3. **Kubectl**

      ```bash
      choco install kubernetes-cli
      
      # Otherwise, follow the various options at -
      https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/ 
      ```

   4. **Helm**

      ```
      choco install kubernetes-helm
      ```

   5. **PowerShell Core**

      ```bash
      # Follow this link and install PowerShell Core for Windows
      https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7.1
      
      # Install Az module for communicating to Azure over Az cmdlet
      Install-Module -Name Az -AllowClobber
      ```

   6. **Lens** - *For monitoring Cluster resources*

      ```bash
      # Follow this link and install Lens for Windows
      https://k8slens.dev/
      ```

   7. (Optional) **Visual Studio Code**

      ```bash
      # Follow this link and install Visual Studio Code
      # This is for better management of scripts and commands
      https://code.visualstudio.com/docs/setup/windows
      ```

   8. (*Optional*) **Docker**

      ```bash
      # Follow this link and install Docker Desktop latest for Windows
      https://docs.docker.com/docker-for-windows/install/
      
      # Install this only if you want to play with Docker images locally
      # This workshop will use a different techniqe so installation of Docker is not needed
      ```

8. **Docker Private Registry**

   - User(s) might want to use *Private Docker registry* to store their scanned, cleaned images and distribute them through the K8s cluster
   - While *Azure Container Registry* is a natural choice, but that means it is an outbound call to *Azure Public Cloud* from the K8s cluster on Azure
   - Preparing a *Docker Registry* is easy - https://docs.docker.com/registry/deploying/
   - This can be setup on the same Jump Server Or on any other machine

9. **Clone** the repo — (TBD) into your local folder somewhere on the VM. Open and browse the files in VS Code editor and have a quick look; check the folder structure as described in the section [above](#deployments)

10. The **Jump Server** is now ready to be used for subsequent deployments

11. **Open** PowerShell Core on the VM. Set cloud option to *Azure Public Cloud*

    ```bash
    az cloud set -n "AzureCloud"
    ```

10. **Login** to Azure Tenant

    ```bash
    az login --tenant <tenant_id>
    
    # This can be a userid based login or a Service Princiapl based login. In either case the logged in credential should have enough privilidges to perform all resource creation
    
    # Ideally an Application Administrator Role shoud be enough to run through all the steps
    ```

    

11. **Prepare** *Infrastructure*

    - Run ***Deployments/Azure-CLI/Setup/aksengine-cluster-preconfig.ps1***
      - ***Example***

        ```bash
        ./aksengine-cluster-preconfig.ps1 --resourceGroup "aks-engine-workshop-rg" --location "eastus" --clusterName "aks-engine-workshop-cluster" --acrName "aksengnacr" --keyVaultName "aks-engine-workshop-kv" --aksVNetName "aks-engine-workshop-vnet" --aksVNetPrefix "193.0.0.0/16", --aksSubnetName s"aks-engine-workshop-subnet" --aksSubnetPrefix "193.0.0.0/23" --appgwSubnetName "aks-engine-workshop-appgw-subnet" --appgwSubnetPrefix "193.0.2.0/24" --appgwName "aks-engine-workshop-appgw" --networkTemplateFileName "aksengine-network-deploy" --acrTemplateFileName "aksengine-acr-deploy" --kvTemplateFileName "aksengine-keyvault-deploy" --pfxCertFileName "<pfxCertFileName>" --rootCertFileName "<rootCertFileName>" --subscriptionId "<subscription_Id>" --objectId "<object_Id>" --baseFolderPath "<base_Folder_Path>"
        ```

      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Following Values should **<u>NOT</u>** be changed. These are file names of template files to be used by the script(s) and filenames have already been set. Unless you change those filenames in your local repo, no need to play around with those name!!

          - **networkTemplateFileName**
          - **acrTemplateFileName**
          - **kvTemplateFileName**
          
        - Provide values for following 3 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*

          - **objectId** - Azure AD objectId of the logged-in user/service principal; this can be found on the-

            ***Azure AD page-> Select User or Service Principal (as the case may be)-> Look at Overview page***

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../AKSEngineWorkshop/Deployments**

        - This scripts deploys following resources on Azure Public Cloud

          - **Azure Container Registry (ACR)** - K8s cluster on Azure would pull images from here 

          - **Azure KeyVault (KV)** - used for storing Service Principals in Azure Public Cloud to be used later while creating the cluster

          - **VNet** for K8s cluster - **aks-engine-workshop-vnet**

          - **Subnet** to host K8s cluster - **aks-engine-workshop-subnet**

          - **Azure AD Service Principal** - This will be used by K8s cluster on while creating the cluster

            This Service Principal is added into the KeyVault - **aks-engine-workshop-kv**; the names would be like -

            1. **<cluster_name>-sp-id** 
            2. **<cluster_name>-sp-secret**

          - **Role** assignments

            1. Assign **Network Contributor** Role to the above Service Principal on the ***VNet*** created above - **aks-engine-workshop-vnet**
            2. Assign **ACRPush** Role to the above Service Principal on the ***ACR*** created above - **aksengnacr**
            3. Assign **Owner** role to the above Service Principal on the ***Subscription***

12. **Setup** K8s cluster on Azure Infrastructure

    - Prepare for **RBAC**

      - **K8s** cluster on Azure would need few parameters from Azure AD for RBAC
      - Follow the link to setup **Azure AD** - https://github.com/Azure/aks-engine/blob/master/docs/topics/aad.md
      - The 4 major parameters needed for subsequent steps -
        - **clientAppID** - Application ID of the Client App as described above
        - **serverAppID** - Application ID of the Server App as described above
        - **tenantID** - The Tenant ID of the Azure AD where the above two applications are created. This can be any valid tenant
        - **adminGroupID** - The Group ID of the Cluster Admin Group created in the above tenant. This group would be given the Cluster Admin privileges after the creation of the K8s cluster

    - Prepare Configuration values for K8s Cluster

      - Browse to ***Deployments/Azure-CLI/Templates/AKSEngine/aks-engine-config.json***
      - This is the Config file used by AKS-engine to deploy new K8s cluster
      - Default values are all set; rest will be supplied at runtime by the following script - **aksengine-cluster-setup**

    - Install **AKS-Engine** on Azure

      - Follow this link to choose latest version to be installed - https://github.com/Azure/aks-engine/releases
      - This workshop uses — **v0.58.0** — https://github.com/Azure/aks-engine/releases/tag/v0.58.0
      - Once installed, you are ready to run the following script to create the K8s cluster

    - Run ***Deployments/Azure-CLI/Setup/aksengine-cluster-setup.ps1***

      - ***Example***

        ```bash
        ./aksengine-cluster-setup.ps1 --resourceGroup "aks-engine-workshop-rg" --location "eastus" --clusterName "aks-engine-workshop-cluster" --keyVaultName "aks-engine-workshop-kv" --aksVNetName "aks-engine-workshop-vnet" --aksSubnetName "aks-engine-workshop-subnet" --clientAppID "<client_AppID>" --serverAppID  "<server_AppID>" --adminGroupID  "<cluster_admin_groupId>" --tenantID  "<cluster_admin_tenantId>" --subscriptionId "<subscription_Id>" --baseFolderPath "<base_Folder_Path>"
        ```

        - Provide values for the Azure AD placeholder values as obtained from above
          - **clientAppID**
          - **serverAppID**
          - **tenantID**
          - **adminGroupID**
        - Provide values for following 2 variables with are displayed as place holders
          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*
          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../AKSEngineWorkshop/Deployments**

13. **Connect** to the Cluster

    - *KubeConfig* is the file to organise your *clusters, users, namespaces* and *authentication* mechanisms

    - Every machine accessing the K8s cluster, a config file is created at the .kube folder location under Home directory

    - In case of AKS-Engine, once the cluster is deployed first time, the generated kubeconfig file would be created at -

      ***Deployments/Azure-CLI/Templates/AKSEngine/Output/ClusterInfo/kubeconfig*** in the Jump Server VM

    - From this workshop, we have created the Jump Server which is a **Windows 2019 DC VM**. So, we should go to the User's Home directory and create a .**kube**

    - Copy this file to .**kube** folder just created above

    - Create System Environment variable called *KUBECONFIG* with the path of the file under .**kube** folder

    - Type in the following command to see if cluster creation ok or not

      ```bash
      kubectl get nodes
      ```

    - This should list down all the nodes in the cluster - for this workshop - it would come up with *3 Master Nodes* and *3 Worker Nodes*. This ensures that cluster is all ok and healthy!

14. **Configure** K8s cluster post creation

    - The K8s cluster is still with Cluster Admin group members

    - Run ***Deployments/Azure-CLI/Setup/aksengine-cluster-postconfig.ps1***

      - ***Example***

        ```bash
        ./aksengine-cluster-postconfig.ps1 --resourceGroup "aks-engine-workshop-rg" --projectName "aks-engine-workshop" --appgwName "aks-engine-workshop-appgw" --aksVNetName "aks-engine-workshop-vnet"  --appgwSubnetName "aks-engine-workshop-appgw-subnet" --appgwTemplateFileName "aksengine-appgw-deploy" --ingControllerIPAddress "193.0.0.200" --ingHostName "<ingressHostName>" --listenerHostName "<listenerHostName>" --baseFolderPath "<base_Folder_Path>"
        ```
        
      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following variable(s) which are displayed as place holders

          - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../AKSEngineWorkshop/Deployments**

        - Following variables need some explanation

          - **projectName** - This is used internally by the script to define names for various resources that are to be deployed on the K8s cluster
          - **clusterInternalName** - This is the name with which the cluster is created - basically **clusterName-<randomId>**. This name can be found at the **KubeConfig** file.

        - This scripts deploys following resources on K8s cluster

          - **Ingress Controller** - **Nginx** is used as *Ingress* for this workshop; but any other *Ingress controller* can be used. This is deployed as a *Private Load Balancer* assigning IP address from the Subnet of the K8s cluster
          - **Application Gateway** - L7 External Load Balancer in front of Nginx Ingress (ILB). This is deployed with-
            - **Multi-Site Listener** - This would allow users to build a multi-tenant architecture
            - **End-to-End SSL** - Supporting SSL termination at the Nginx Ingress controller inside the cluster

15. **Add** more Node pools to the Cluster

    - Users can add more Node pools to the existing with different Node sizes than the initial ones created along with the cluster

    - Define a config file for Node pool e.g, ***Deployments/Azure-CLI/Templates/AKSEngine/aks-engine-nodepool.json***

    - A sample one is already created. Browse the file and change as per the requirement

    - Run ***Deployments/Azure-CLI/Setup/aksengine-cluster-nodepool.ps1***

      - ***Example***

        ```bash
        ./aksengine-cluster-nodepool.ps1 --mode "add" --resourceGroup "aks-engine-workshop-rg"
        --location "eastus" --clusterName "aks-engine-workshop-cluster" --keyVaultName "aks-engine-workshop-kv" --subscriptionId "<subscription_Id>" --nodePoolConfigFileName "aks-engine-nodepool" 
        --nodepoolName "<nodepool_name>" --baseFolderPath "<base_Folder_Path>"
      ```
      
    - ***Note***
      
      - The values are provided as example only. They can be used as-is as long resources with same name does not exist!
      
      - Provide values for following 2 variables with are displayed as place holders
      
        - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*
      
        - **baseFolderPath** - This is path of the Deployments folder in the local repo. Script would actually be able to flow through the folder hierarchy and run other necessary scripts. So as an example this will be the complete physical path like - **/Users/<user_name>/../AKSEngineWorkshop/Deployments**
      
      - Following Values should **<u>NOT</u>** be changed. These are the file names of template files to be used by the script(s) and filenames have already been set. Unless you change those filenames in your local repo, no need to play around with those name!!
      
        - **nodePoolConfigFileName**
      
      - This scripts deploys following resources on Azure
      
          - **New Node pool** - in this workshop it is named as - **aksiotpool**
          - **Node pool count** - **3** - in this workshop

16. **Deploy** Ingress object

    - **Ingress** objects are used for Routing to appropriate services within the cluster

      *Ref*: ***Deployments/YAMLs/DEV/Ingress/aksengine-ingress.yaml***

      ```yaml
      apiVersion: networking.k8s.io/v1beta1
      kind: Ingress
      metadata:
        name: aksengine-ingress
        namespace: aks-engine-workshop-dev
        annotations:
          kubernetes.io/ingress.class: nginx
          nginx.ingress.kubernetes.io/rewrite-target: /$1
          nginx.ingress.kubernetes.io/enable-cors: "true"
      spec:
        tls:
        - hosts:
          - "*.internal.wkshpdev.com"
          secretName: aks-engine-tls-secret
        rules:
        - host: aks-engine-workshop-dev.internal.wkshpdev.com
          http:
            paths:
            - path: /nginx/?(.*)
              backend:
                serviceName: nginx-svc
                servicePort: 80
            - path: /?(.*)
              backend:
                serviceName: ratingsweb-service
                servicePort: 80
            - path: /ratings/?(.*)
              backend:
                serviceName: ratingsapi-service
                servicePort: 80
      ```

    - **Deploy** Ingress object

      ```bash
      kubectl apply -f <ingress_file_name>.yaml
      ```

    - This is used in the workshop. Users can bring in their own Ingress object as per the requirements

      

17. **Deploy** MicroServices

    - This can be done in multiple ways. This workshop deploys some ready-made micro-services using ACR build option. The applications deployed are as examples only!

    - Following steps deploys various components and services

      - **Namespaces**

        ```bash
        kubectl create ns aks-engine-workshop-dev
        ```

      - **MongoDB**

        ```bash
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm search repo bitnami
        helm install ratingsdb bitnami/mongodb --namespace db --set auth.username=ratings-user,auth.password=ratings-pwd,auth.database=ratingsdb --set nodeSelector.agentpool=akssyspool,defaultBackend.nodeSelector.agentpool=akssyspool
        ```

      - **Secrets**

        ```bash
        kubectl create secret generic aks-engine-mongo-secret --namespace aks-engine-workshop-dev --from-literal=MONGOCONNECTION="mongodb://ratings-user:ratings-pwd@ratingsdb-mongodb.db:27017/ratingsdb"
        
        kubectl create secret docker-registry aks-engine-acr-secret -n aks-engine-workshop-dev --docker-server=<acr_server_name> --docker-username=<acr_user_name> --docker-password=<acr_user_password>
        ```

      - **Build and Push Images to ACR**

        ```bash
        # Build RatingsAPI Image
        az acr build -r <acr_name> https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api -t azcashacr.azurecr.io/ratings-api:v1.0.0
        
        # Build RatingsWeb Image
        az acr build -r <acr_name> https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web -t azcashacr.azurecr.io/ratings-web:v1.0.0
        ```

      - **Deploy** APIs

        - **Nginx** - ***APIs/YAMLs/DEV/Nginx***

          ```bash
          kubectl apply -f <nginx_folder_path>
          ```

        - **RatingsWeb** - ***APIs/YAMLs/DEV/RatingsWeb***

          ```bash
          kubectl apply -f <rtingsweb_folder_path>
          ```

        - **RatingsWeb** - ***APIs/YAMLs/DEV/RatingsAPI***

          ```bash
          kubectl apply -f <rtingsapi_folder_path>
          ```

18. **Remove** K8s Cluster

    - Since this is an unmanaged K8s cluster, lifecycle of each component & resources created are to be maintained by the user(s)

    - Deletion of each resource is painful through a script; can anyway be done manually by pick-n-choose method!

    - Alternate option is to remove the entire resource group on Azure which contains all the resources - K8s as well as ancillary services

    - The following script would actually remove the rescue group

    - Run ***Deployments/Azure-CLI/Setup/aksengine-cluster-remove.ps1***

      - ***Example***

        ```bash
        ./aksengine-cluster-remove.ps1 shouldRemoveSP = "false" --resourceGroup "aks-engine-workshop-rg"
        --clusterName "aks-engine-workshop-cluster" --subscriptionId "<subscription_Id>"
        ```
        
      - ***Note***

        - The values are provided as example only. They can be used as-is as long resources with same name does not exist!

        - Provide values for following 2 variables with are displayed as place holders

          - **subscriptionId** - The *SubscriptionId* of the logged-in user/service principal. This workshop used a Microsoft userid to Login and run through this - *<ms-alias>@microsoft.com*


          


### References

- **Source** - https://github.com/monojit18/ASHK8sWorkshop.git
- **Azure Container Registry** - https://docs.microsoft.com/en-us/azure/container-registry/
- **Docker Private Registry** - https://docs.docker.com/registry/deploying/
- **AKS-Engine Docs** - https://github.com/Azure/aks-engine/tree/master/docs