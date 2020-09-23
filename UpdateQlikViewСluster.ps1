<#

Скрипт автоматизации обновления QlikView в кластерной среде

QlikView   v0.96     

#>

cls

"Время обновления {0}. Пользователь проивевший обновление {1}" -f (get-date), (Get-Content Env:\USERNAME)

$servers =  ''

$frgColorAction = "Yellow"

$InstallPath = ''

$CopyConfigPath = ''

$UserName = ""

$Password = "" 

$Cred = Get-Credential

$Service = ""
 
$ErrorActionPreference = 'SilentlyContinue'

#Функция создания папок согласно имени служб
function Create-Folder { $servers
   Write-Host "Создание папок"  -ForegroundColor $frgColorAction
        Foreach ($server in $servers) {
            if ((Get-Service -ComputerName $server -Name QlikViewDistributionService).count -ne 0 )  {
                New-item -Path ($CopyConfigPath + $server +"\Program Files\QDS")  -ItemType Directory -Verbose   -ErrorAction SilentlyContinue  
                New-item -Path ($CopyConfigPath + $server +"\ProgramData\QDS")    -ItemType Directory -Verbose   -ErrorAction SilentlyContinue    
            }
            if ((Get-Service -ComputerName $server -Name QlikviewWebserver).count -ne 0 ) {
                New-item -Path ($CopyConfigPath + $server +"\ProgramData\")       -ItemType Directory -Verbose   -ErrorAction SilentlyContinue       
            }
            if ((Get-Service -ComputerName $server -Name QlikViewServer).count -ne 0 ) {
                New-item -Path ($CopyConfigPath + $server +"\ProgramData\QVS")    -ItemType Directory -Verbose   -ErrorAction SilentlyContinue   
            }
            if ((Get-Service -ComputerName $server -Name QlikViewManagementService).count -ne 0 ) {
                New-item -Path ($CopyConfigPath + $server +"\Program Files\QMC")  -ItemType Directory -Verbose   -ErrorAction SilentlyContinue     
                New-item -Path ($CopyConfigPath + $server +"\ProgramData\QMC")    -ItemType Directory -Verbose   -ErrorAction SilentlyContinue     
            }
            if ((Get-Service -ComputerName $server -Name QlikViewDirectoryServiceConnector).count -ne 0 ) {
                New-item -Path ($CopyConfigPath + $server +"\Program Files\DSC")  -ItemType Directory -Verbose   -ErrorAction SilentlyContinue    
                New-item -Path ($CopyConfigPath + $server +"\ProgramData\DSC")    -ItemType Director  -Verbose   -ErrorAction SilentlyContinue    
            }

        }

    } 

#Копирование конфигурационных файлов С СЕРВЕРОВ КЛАСТЕРА
function Copy-ConfigFrom { $servers
    Write-Host "Копирование конфигурационных файлов с серверов кластера"  -ForegroundColor $frgColorAction
            Foreach ($server in $servers) { $server 
                   if ((Get-Service -ComputerName $server -Name QlikviewWebserver).count -ne 0 )  {
                    Copy-Item  ("\\"+ $server +"\c$\Program Files\QlikView\Server\Web Server\QVWebServer.exe.config") ($CopyConfigPath + $server +"\Program Files\QVWS") -ErrorAction SilentlyContinue  -Verbose
                    Copy-Item  ("\\"+ $server +"\c$\ProgramData\QlikTech\WebServer\config.xml")  ($CopyConfigPath + $server +"\ProgramData\") -ErrorAction SilentlyContinue  -Verbose

                }

                if ((Get-Service -ComputerName $server -Name QlikViewDirectoryServiceConnector).count -ne 0 )  {
                    Copy-Item  ("\\"+ $server +"\c$\Program Files\QlikView\Directory Service Connector\QVDirectoryServiceConnector.exe.config")  ($CopyConfigPath + $server +"\Program Files\DSC") -ErrorAction SilentlyContinue  -Verbose
                    Copy-Item  ("\\"+ $server +"\c$\ProgramData\QlikTech\DirectoryServiceConnector\Config.xml")  ($CopyConfigPath + $server +"\ProgramData\DSC") -ErrorAction SilentlyContinue  -Verbose

                }

                if ((Get-Service -ComputerName $server -Name QlikViewManagementService).count -ne 0 ) {
                    Copy-Item  ("\\"+ $server +"\c$\Program Files\QlikView\Management Service\QVManagementService.exe.config")  ($CopyConfigPath + $server +"\Program Files\QMC") -ErrorAction SilentlyContinue  -Verbose
                    Copy-Item  ("\\"+ $server +"\c$\ProgramData\QlikTech\ManagementService\Config.xml")  ($CopyConfigPath + $server +"\ProgramData\QMC") -ErrorAction SilentlyContinue  -Verbose

                }

            if ((Get-Service -ComputerName $server -Name QlikViewDistributionService).count -ne 0 ) {
                    Copy-Item  ("\\"+ $server +"\c$\Program Files\QlikView\Directory Service Connector\QVDirectoryServiceConnector.exe.config")  ($CopyConfigPath + $server +"\Program Files\DSC") -Verbose
                    Copy-Item  ("\\"+ $server +"\c$\Program Files\QlikView\Directory Service Connector\QVDistributionService.exe.config")  ($CopyConfigPath + $server +"\Program Files\DSC") -ErrorAction SilentlyContinue  -Verbose

            }

                if ((Get-Service -ComputerName $server -Name QlikViewServer).count -ne 0 )  {
                    Copy-Item  ("\\"+ $server +"\c$\ProgramData\QlikTech\Lef.txt")  ($CopyConfigPath + $server +"\ProgramData\QVS") -ErrorAction SilentlyContinue  -Verbose
                    Copy-Item  ("\\"+ $server +"\c$\ProgramData\QlikTech\QlikViewServer\Settings.ini")  ($CopyConfigPath + $server +"\ProgramData\QVS") -ErrorAction SilentlyContinue  -Verbose

            }

        }

    }

#Проверка папок и создание в случае их отсуствия.
function Check-Folder {  $servers
Write-Host "Проверка и создание папок на серверах" -ForegroundColor $frgColorAction
     ForEach ($server in $servers)  { $server
        $path = Test-Path  "\\'$server'\c$\Install\"
            if ($path -eq $false){
                New-Item -Path ("\\"+ $server+ "\C$\install\") -ItemType Directory -Verbose

            }

        }

     }

#Копирование инсталяционного файла на сервера кластера
function Copy-Install {  $servers
  Write-Host "Копирование инсталяционных файлов на сервера кластера" -ForegroundColor $frgColorAction
    Foreach ($server in $servers) { $server
        Copy-Item  ("\\"+$server+"\c$\Install\") -Verbose -Recurse -Force

        }

  }

#Остановка служб SCOM
function Stop-SCOM {
    Write-Host "Остановка служб SCOM" -ForegroundColor $frgColorAction
    foreach ($server in $servers) {
        Get-Service -Name "HealthService*" -ComputerName $server | Stop-Service  -Force -Verbose

    }

}
                   
#Остановка служб QlikView
function Stop-QVSServices {
    Write-Host "Остановка служб Qlikview" -ForegroundColor $frgColorAction
    foreach ($server in $servers) {
        Get-Service -Name "Qlik*" -ComputerName $server | Stop-Service -Force  -Verbose

    }

}

#Копирование конфигурационных файлов НА СЕРВЕРА КЛАСТЕРА
function Copy_ToConfig { $servers
    Write-Host "Копирование конфигурационных файлов НА СЕРВЕРА КЛАСТЕРА" -ForegroundColor $frgColorAction
        foreach ($server in $servers) {
            if ((Get-Service -ComputerName $server -Name QlikviewWebserver).count -ne 0 )  {
                Copy-Item  ($CopyConfigpath + $server +"\Program Files\QVWS\QVWebServer.exe.config")  ("\\"+ $server +"\c$\Program Files\QlikView\Server\Web Server\") -Force -Verbose
                Copy-Item  ($CopyConfigpath + $server +"\ProgramData\config.xml") ("\\"+ $server +"\c$\ProgramData\QlikTech\WebServer\") -Force  -ErrorAction SilentlyContinue  -Verbose
                }
            if  ((Get-Service -ComputerName $server -Name QlikViewDirectoryServiceConnector).count -ne 0 )  {
                Copy-Item  ($CopyConfigpath + $server +"\Program Files\DSC\QVDirectoryServiceConnector.exe.config")  ("\\"+ $server +"\c$\Program Files\QlikView\Directory Service Connector\") -Force -Verbose
                Copy-Item  ($CopyConfigpath + $server +"\ProgramData\DSC\Config.xml") ("\\"+ $server +"\c$\ProgramData\QlikTech\DirectoryServiceConnector\") -Force -ErrorAction SilentlyContinue -Verbose
                }
            if ((Get-Service -ComputerName $server -Name QlikViewManagementService).count -ne 0 ) {
                Copy-Item  ($CopyConfigpath + $server +"\Program Files\QMC\QVManagementService.exe.config") ("\\"+ $server +"\c$\Program Files\QlikView\Management Service\") -Force -Verbose  
                Copy-Item  ($CopyConfigpath + $server +"\ProgramData\QMC\Config.xml") ("\\"+ $server +"\c$\ProgramData\QlikTech\ManagementService\") -Force -ErrorAction SilentlyContinue -Verbose
                }
            if ((Get-Service -ComputerName $server -Name QlikViewDistributionService).count -ne 0 ) {
                Copy-Item ($CopyConfigpath + $server +"\Program Files\DSC\QVDistributionService.exe.config") Copy-Item  ("\\"+ $server +"\c$\Program Files\QlikView\Directory Service Connector\") -ErrorAction SilentlyContinue -Verbose
                }
            if ((Get-Service -ComputerName $server -Name QlikviewServer).count -ne 0 ) {
                Copy-Item ($CopyConfigpath + $server +"\ProgramData\QVS\Settings.ini") ("\\"+ $server +"\c$\ProgramData\QlikTech\QlikViewServer\") -Force -ErrorAction SilentlyContinue -Verbose

                }

        }                  

    }        

#Назначение пароля и имени пользователя службам QlikView на нодах кластера 
function Set-UserName {

    Write-Host "Назначение пароля и имени пользователя службам QlikView на нодах кластера" -ForegroundColor $frgColorAction
        $svcD = Get-WmiObject win32_service -computername $servers -filter "name='QlikviewDirectoryServiceConnector'" -Credential $cred
        $ChangeStatus = $svcD.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null)

        $svcD = Get-WmiObject win32_service -computername $servers -filter "name='QlikViewDistributionService'" -Credential $cred
        $ChangeStatus = $svcD.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null)

        $svcD = Get-WmiObject win32_service -computername $servers -filter "name='QlikviewManagementService'" -Credential $cred
        $ChangeStatus = $svcD.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null)

        $svcD = Get-WmiObject win32_service -computername $servers -filter "name='QlikviewServer'" -Credential $cred
        $ChangeStatus = $svcD.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null)

        $svcD = Get-WmiObject win32_service -computername $servers -filter "name='QlikViewServiceDispatcher'" -Credential $cred
        $ChangeStatus = $svcD.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null)

        $svcD = Get-WmiObject win32_service -computername $servers -filter "name='QlikviewWebserver'" -Credential $cred
        $ChangeStatus = $svcD.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null)
}

#Запуск служб SCOM
function Start-SCOM {
    Write-Host "Запуск служб SCOM" -ForegroundColor $frgColorAction
        foreach ($server in $servers) {
            Get-Service -Name "*HealthService*" -ComputerName $server | Start-Service  -Verbose

            }

       }

#Запуск служб QlikView
function Start-QVSServices {
    Write-Host "Запуск служб QlikView" -ForegroundColor $frgColorAction
        foreach ($server in $servers) {
            Get-Service -Name "Qlik*" -ComputerName $server | Start-Service  -Verbose

    }

}

Create-Folder
Copy-ConfigFrom
Check-Folder
Copy-Install
Stop-SCOM
Stop-QVSServices
Set-UserName
Copy_ToConfig
Start-QVSServices
Start-SCOM


 
