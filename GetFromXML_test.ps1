Clear-Host
$Xml =  ""
$XPath = "//AddRecipient"
$DoneXML = Select-Xml -Path $Xml -XPath $XPath  | foreach {$_.Node.ID}
$LocalDomanName = $(Get-ADDomain).NetBIOSName

[xml]$XmlApp = Get-Content $Xml
$AppName = $XmlApp.DistributeTask.Name
$report = @()

foreach ($item in $DoneXML) {
    $GetObject = "" | Select-Object AppName, SamAccountName, CN, ObjectClass
    $IdentityDomainName = $item.Split("\")[0]
    $Identity = $item.Split("\")[-1]
    Write-Output "Working with object: $Identity. Domain: $IdentityDomainName"
    if ($IdentityDomainName -ne $LocalDomanName ) {
    #Write-Output "User not found"
    $PSObject = New-Object PSObject -Property @{
        SamAccountName = $identity
        CN = "N/A"
        ObjectClass = "N/A"
        AppName = "N/A"
    }
    }
    else {
    $item = Get-ADObject -Filter "SamAccountName -eq '$($identity)'" -Properties SamAccountName, CN, ObjectClass
    $PSObject = New-Object PSObject -Property @{
        SamAccountName = $item.SamAccountName
        CN = $item.CN
        ObjectClass = $item.ObjectClass
        AppName = $AppName
    }
    }
    $report +=  $PSObject
    }

$report | Sort-Object -Property AppName, SamAccountName -Unique  | Format-Table AppName, SamAccountName, CN, ObjectClass -Wrap -AutoSize
