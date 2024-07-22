Import-Module AzureRM 
Import-Module AzureRM.Insights

#UPDATE THIS 
$username = "rmdoliveira.externo@creditoagricola.pt" 
$myPassword = "VPCLUroJ.$L0c4l$*"
#UPDATE THIS

#Subscription and Directory IDs
$subscriptionID = "464619d0-ce5e-4083-ac6e-92fd3bccf937"
$tenantId = "cd49f469-eabf-4bb1-8520-4991392c368b" 

#Login to the portal
$SecurePassword = $myPassword | ConvertTo-SecureString -AsPlainText -Force 
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $SecurePassword 
$SubscriptionName = "DSP-Infra-MG"
Login-AzureRmAccount -Credential $cred -Tenant $tenantId -SubscriptionName $SubscriptionName

#Resource Group
$resourceGroupName = "ne-mg-AlertsTest-oms-rg"

#File Paths. I used this path you can choose any other.
$templateFilePath = "C:\Users\c89597375\OneDrive\SCOM\Deploy_Azure\azuredeploy\azuredeploy.json"
$parametersFilePath = "C:\Users\c89597375\OneDrive\SCOM\Deploy_Azure\azuredeploy\azuredeploy.parameters.json"

################## VIRTUAL MACHINES RESOURCES ###########################################################################
#Get Resources
$VMColl = Get-AzureRmResource -ResourceType "Microsoft.Compute/VirtualMachines" | Select-Object -Property ResourceId,Name
######################################################################################################################### 

Write-Host "Creating Metric Alerts for Virtual Machines"

################## CPU PERCENTAGE FOR VIRTUAL MACHINES ##############################
foreach ($VMID in $VMColl){

#Parameters
$strVMID = $VMID.ResourceId
$strVMName = $VMID.Name

$alertName = "CPU Performance " + $strVMName
$metricName = "Percentage CPU"
$threshold = "90"
$actionGroupId = "YOUR ACTION GROUP"
$timeAggregation = "Average" # Average, Minimum, Maximum, Total
$alertDescription = "The percentage of allocated compute units that are currently in use by the Virtual Machine(s)"
$operator = "GreaterThan" # Equals, NotEquals, GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual
$alertSeverity = 3 # 0,1,2,3,4

#Get JSON
$paramFile = Get-Content $parametersFilePath -Raw | ConvertFrom-Json

#Update Values
$paramFile.parameters.alertName.value = $alertName
$paramFile.parameters.metricName.value = $metricName
$paramFile.parameters.resourceId.value = $strVMID
$paramFile.parameters.threshold.value = $threshold
$paramFile.parameters.actionGroupId.value = $actionGroupId
$paramFile.parameters.timeAggregation.value = $timeAggregation
$paramFile.parameters.alertDescription.value = $alertDescription
$paramFile.parameters.operator.value = $operator
$paramFile.parameters.alertSeverity.value = $alertSeverity

#Update JSON
$UpdatedJSON = $paramFile | ConvertTo-Json
$UpdatedJSON > $parametersFilePath

#Deploy Template
$DeploymentName = "CPUPerformanceAlerts-$strVMName"
$AlertDeployment = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -AsJob

} 
