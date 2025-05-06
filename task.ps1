$location                  = "uksouth"
$resourceGroupName         = "mate-azure-task-10"
$networkSecurityGroupName  = "defaultnsg"
$virtualNetworkName        = "vnet"
$subnetName                = "default"
$vnetAddressPrefix         = "10.0.0.0/16"
$subnetAddressPrefix       = "10.0.0.0/24"
$sshKeyName                = "linuxboxsshkey"
$sshKeyPublicKey           = Get-Content "~/.ssh/id_rsa.pub"
$vmNameBase                = "matebox"
$vmImage                   = "Ubuntu2204"
$vmSize                    = "Standard_B1s"

Write-Host "Creating resource group '$resourceGroupName' in $location..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating NSG '$networkSecurityGroupName'..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 `
    -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 `
    -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow

New-AzNetworkSecurityGroup `
  -Name $networkSecurityGroupName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

Write-Host "Creating VNet '$virtualNetworkName' with subnet '$subnetName'..."
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork `
  -Name $virtualNetworkName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -AddressPrefix $vnetAddressPrefix `
  -Subnet $subnet

Write-Host "Importing SSH public key resource '$sshKeyName'..."
New-AzSshKey `
  -Name $sshKeyName `
  -ResourceGroupName $resourceGroupName `
  -PublicKey $sshKeyPublicKey

# ────────────── Deploy TWO Linux VMs ──────────────

$commonVmParams = @{
    ResourceGroupName   = $resourceGroupName
    Location            = $location
    VirtualNetworkName  = $virtualNetworkName
    SubnetName          = $subnetName
    SecurityGroupName   = $networkSecurityGroupName
    Image               = $vmImage
    Size                = $vmSize
    SshKeyName          = $sshKeyName
    # Видалено DisablePasswordAuthentication
}

Write-Host "Deploying VM '$vmNameBase-1' in zone 1..."
New-AzVm @commonVmParams `
  -Name "${vmNameBase}-1" `
  -Zone 1

Write-Host "Deploying VM '$vmNameBase-2' in zone 2..."
New-AzVm @commonVmParams `
  -Name "${vmNameBase}-2" `
  -Zone 2

Write-Host "`n✅ Successfully deployed two VMs ($vmNameBase-1, $vmNameBase-2) across Availability Zones 1 & 2."