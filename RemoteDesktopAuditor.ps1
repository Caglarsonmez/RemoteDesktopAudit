import-module activedirectory
<# User Variables #>
$strContent     = "D:\sampled_computers_remote.txt" # List of computer account names that included in sample. List contents must be seperated with new line
$strMainPath    = "D:\sampled_computers_remote.csv" # Path of main output file
$strGrPath      = "D:\sampled_computers_group_members.csv" # Path for group members CSV
$strADQueryPath = "D:\sampled_computers_remoteusers_ADQuery.csv" # Path for AD query of remote desktop users
<# User Variables #>

<# General Variables -Don't change #>
$Computers = Get-Content $strContent
$Properties = @('SamAccountName', 'DisplayName', 'Enabled', 'Company', 'physicalDeliveryOfficeName', 'title', 'manager', 'Created')
$remotelist    = @() 
$remotelist2   = @() 
$resultsarray = @()
<# General Variables -Don't change #>

foreach ($comp in $Computers) <# Iterating over sampled computer accounts for retrieving members of those computers' remote desktop users group #> {
        
        $computer     = [ADSI]("WinNT://" + $comp + ",computer") 
        $RemoteGroup   = $computer.psbase.children.find("Remote Desktop Users")
        $Remotemembers = $RemoteGroup.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} 
        foreach ($remote in $Remotemembers)  { $remotelist += $comp + "," + $remote
                                             $remotelist2 += $remote} 
        $objlist = $remotelist | Select-Object @{Name='Computers,Remotes';Expression={$_}}
        $objlist | Export-Csv -Append -Notypeinformation -Encoding "Unicode" -Path $strMainPath    
        }

<# Iterating over groups for retrieving members. In case there were groups as members of remote desktop users group#> 
$groups = $remotelist2 |  select -uniq # removing duplicate items from initial remote desktop users 
$resultsarray = @()
foreach ($group in $groups) {
        $resultsarray += Get-ADGroupMember -Id $group -recursive -ErrorAction SilentlyContinue | Get-ADUser -Properties $Properties -ErrorAction SilentlyContinue | Select 'SamAccountName', 'DisplayName', 'Enabled', 'Company', 'physicalDeliveryOfficeName', 'title', 'manager', 'Created', @{Expression={$group};Label="Group Name"} 
        }
        $resultsarray | Export-csv -path $strGrPath -notypeinformation -Encoding {Unicode} -Delimiter ";" 

<# Iterating over remote desktop users list for retrieving AD properties of these users #>
$Remotes = $remotelist2 |  select -uniq # removing duplicate items from initial remote desktop users 
foreach ($rem in $Remotes) 
        {
        Get-ADUser -Identity $rem -Properties $Properties -ErrorAction SilentlyContinue | Select 'SamAccountName', 'DisplayName', 'Enabled', 'Company', 'physicalDeliveryOfficeName', 'title', 'manager', 'Created' | Export-Csv -Notypeinformation -Encoding "Unicode" -Path $strADQueryPath -Append -Delimiter ";"
        }
        
