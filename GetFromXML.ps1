Clear-Host

$Xml =  ""

$XPath = "//AddRecipient"

$DoneXML = Select-Xml -Path $Xml -XPath $XPath  | foreach {$_.Node.ID}

$ResultXML = foreach ($DoneXMLs in $DoneXML) {

    $DoneXMLs.Split("\")[-1]

     

}

[xml]$XmlApp = Get-Content $Xml

$f = $XmlApp.DistributeTask.Name

$obj = New-Object -TypeName psobject

$obj | Add-Member -MemberType NoteProperty -Name AppName -Value $f

$report = @()

 
foreach ($GetLogin in $ResultXML) {    

   $ErrorActionPreference = 'SilentlyContinue'


    $GetObject = "" | Select-Object AppName, SamAccountName, CN, ObjectClass -ErrorAction SilentlyContinue


    $Users = Get-ADUser -Identity $GetLogin -Properties SamAccountName, CN, ObjectClass -ErrorAction SilentlyContinue

try        

    {

        if (Get-ADObject -Filter ('ObjectClass -eq "user" -and   SamAccountName -eq $GetLogin') -ErrorAction SilentlyContinue){

            $GetObject.SamAccountName = $Users.SamAccountName

            $GetObject.CN = $Users.CN

            $GetObject.ObjectClass = $Users.ObjectClass

            $GetObject.AppName = $obj.AppName

        }  

        $Groups = Get-ADGroup -Identity $GetLogin -Properties SamAccountName, CN, ObjectClass -ErrorAction SilentlyContinue

       

        if (Get-ADObject -Filter ('ObjectClass -eq "group" -and   SamAccountName -eq $GetLogin') -ErrorAction SilentlyContinue) {

           $GetObject.SamAccountName = $Groups.SamAccountName

           $GetObject.CN = $Groups.CN

           $GetObject.ObjectClass = $Groups.ObjectClass  

           $GetObject.AppName = $obj.AppName

        }

   

    }    

catch

     {   

          $Groups = Get-ADGroup -Identity $GetLogin -Properties SamAccountName, CN, ObjectClass -ErrorAction

          

          if (Get-ADObject -Filter ('ObjectClass -ne "group" -and   SamAccountName -ne $GetLogin') -ErrorAction SilentlyContinue ) {

            $GetObject.SamAccountName = $ResultXML

            $GetObject.CN = "N/A"

            $GetObject.ObjectClass = "N/A"  

            $GetObject.AppName = "N/A"

         }  

     

          $Users = Get-ADUser -Identity $GetLogin -Properties SamAccountName, CN, ObjectClass -ErrorAction SilentlyContinue

 

          if (Get-ADObject -Filter ('ObjectClass -ne "user" -and   SamAccountName -ne $GetLogin') -ErrorAction SilentlyContinue ){

            $GetObject.SamAccountName = $ResultXML

            $GetObject.CN = "NULL"

            $GetObject.ObjectClass = "NULL"

            $GetObject.AppName = "NULL"

        }  

     

        else {

            $GetObject.SamAccountName = "NULL"

            $GetObject.CN = "NULL"

            $GetObject.ObjectClass = "NULL"

            $GetObject.AppName = "NULL"

            }

     }

                 
$report +=  $GetObject

}

$report | Sort-Object -Property AppName, SamAccountName -Unique  | Format-Table AppName, SamAccountName, CN, ObjectClass -Wrap -AutoSize
