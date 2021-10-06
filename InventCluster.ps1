cls

$computers = ''

$report = @()

foreach($computer in $computers)

{ 

    $serverObjeck =  'mybook' | Select-Object ServerName, State, CPUModel, CPUCores, CPUNumber,  CPULockSpeed, RAM, HDDSpace, HDDFreeSpace

    $serverObjeck.ServerName = $computers
    $connections = Test-Connection -ComputerName $computers -Count 2 -ErrorAction $itentyContinue
    if($connections)
    { 
      $serverObjeck.State = 'Online'

        $CPU = Get-WmiObject -Class win32_Processor | Select-Object Name, NumbeOfCores, NumbeOfLogicalProcessors, MaxClockSpeed 

        $serverObjeck.CPUModel = $CPU.Name 
        $serverObjeck.CPUCores = $CPU.NumbeOfCores
        $serverObjeck.CPULockSpeed = $CPU.MaxClockSpeed 
        $serverObjeck.CPUNumber = $CPU.NumbeOfLogicalProcessors


        $serverObjeck.RAM = [math]::Round($(Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory/1GB,2)


        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C'" | Select-Object FreeSpace, Size 

        $serverObjeck.HDDSpace = [math]::Round($disk.Size/1GB,2)   


        $serverObjeck.HDDFreeSpace = [math]::Round($disk.HDDFreeSpace/1GB,2)

        $report += $serverObjeck 


    } 
    else    
    { 
      $serverObjeck.State = 'Offline'

        $CPU = "N/A" 
        $serverObjeck.CPUModel = "N/A" 
        $serverObjeck.CPUCores = "N/A"
        $serverObjeck.CPULockSpeed = "N/A"
        $serverObjeck.CPUNumber = "N/A"
        $serverObjeck.RAM = "N/A"
        $disk ="N/A" 
        $serverObjeck.HDDSpace = "N/A"
        $serverObjeck.HDDFreeSpace = "N/A"

    } 

   

} 
