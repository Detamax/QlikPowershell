Clear-Host


function qmsCreateCredentials {
    param([string]$qmsUri,[string]$domain,[string]$userName,[string]$plainPwd)

    $secPwd = New-Object System.Security.SecureString
    [char[]]$plainPwd | foreach {$secPwd.AppendChar($_)}

    $myCred = new-object System.Net.NetworkCredential ($userName, $secPwd, $domain)
    $uri = New-Object System.Uri($qmsUri)
    $myCache = New-Object System.Net.CredentialCache
    $myCache.Add($uri, "NTLM", $myCred)

    return ,$myCache
}

function qmsCreateSoapBody {
    param([string]$command,[Hashtable]$params)

    $body = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body>'

    if($params.Count -gt 0) {
        $body += '<'+$command+' xmlns="'+$Script:qmsNS+'">'

        $params.Keys.GetEnumerator() | % {
            $body += "<$_>"+$params[$_]+"</$_>"
        }

        $body += '</'+$command+'>'
    } else {
        $body += '<'+$command+' xmlns="'+$Script:qmsNS+'" />'
    }

    $body += '</soap:Body></soap:Envelope>'

    return $body
}

function qmsInvokeRequest {
    param([string]$command,[Hashtable]$params)
    
    $xml = New-Object -TypeName XML

    $soapAction = $Script:qmsNS+$Script:qmsInterface+'/'+$command
    $soapBody = qmsCreateSoapBody $command $params

    #Write-Host "`nsoapAction="$soapAction
    #Write-Host "`nsoapBody="$soapBody

    $webRequest = [System.Net.WebRequest]::Create($Script:qmsPath)
    $webRequest.Credentials = $Script:credCache
    $webRequest.Method = "POST"
    $webRequest.ContentType = "text/xml; charset=utf-8";
    $webRequest.UserAgent = "Mozilla/4.0 (compatible; MSIE 6.0; MS Web Services Client Protocol 4.0.30319.42000)"
    
    if($command -ne "GetTimeLimitedServiceKey") {
        $webRequest.Headers.Add("X-Service-Key",$Script:serviceKey)
    }

    $webRequest.Headers.Add("SOAPAction",$soapAction)

    $encodedContent = [System.Text.Encoding]::UTF8.GetBytes($soapBody)
    if($encodedContent.length -gt 0) {
        $webRequest.ContentLength = $encodedContent.length
        $requestStream = $webRequest.GetRequestStream()
        $requestStream.Write($encodedContent, 0, $encodedContent.length)
        $requestStream.Close()
    } else {
        $webRequest.ContentLength = 0
    }
    
    try {
        $resp = $webRequest.GetResponse()

        $rs = $resp.GetResponseStream();
        [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs
        [string] $respStr = $sr.ReadToEnd()

        $xml.LoadXml($respStr)
    } catch {
        Write-Host -f Red $Error[0].Exception.ErrorRecord.Exception
    }

    return $xml
}

####################################################################


$hostName = ""
$userDomain = "" 
$userName = ""
$userPassword = ""

$logDir = "C:\Works"
$taskName = "Job name"
$zabbixKeyName = "job_name_status"

####################################################################

$Script:qmsPath = "http://"+$hostName+":4799/QMS/Service"
$Script:credCache = qmsCreateCredentials $Script:qmsPath $userDomain $userName $userPassword

$Script:qmsNS = "http://ws.qliktech.com/QMS/12/2/"
$Script:qmsInterface = "IQMS2"

$Script:serviceKey = ""
$qdsId = ""
$qvsId = ""
$taskId = ""

####################################################################

$gtlskResp = qmsInvokeRequest "GetTimeLimitedServiceKey"

$Script:serviceKey = $gtlskResp.Envelope.Body.GetTimeLimitedServiceKeyResponse.GetTimeLimitedServiceKeyResult
#Write-Host "ServiceKey = $Script:serviceKey"

if(!$Script:serviceKey) {break}

####################################################################

$gsResp = qmsInvokeRequest "GetServices" @{"serviceTypes"="QlikViewDistributionService"}
$qdsList = $gsResp.Envelope.Body.GetServicesResponse.GetServicesResult.ServiceInfo | ?{$_.Type -eq "QlikViewDistributionService"}


if(!$qdsList) {break}

####################################################################

$gtResp = qmsInvokeRequest "GetTasks" @{"qdsID"=$qdsList.Id}
$taskInfo = $gtResp.Envelope.Body.GetTasksResponse.GetTasksResult.TaskInfo | ?{$_.Name -eq $taskName}

if(!$taskInfo) {break}

$gtsResp = qmsInvokeRequest "GetTaskStatus" @{"scope"="All";"taskID"=$taskInfo.ID;}
$taskExtendedInfo = $gtsResp.Envelope.Body.GetTaskStatusResponse.GetTaskStatusResult.Extended
if(!$taskExtendedInfo) {break}


#if ($taskExtendedInfo.LastLogMessages -like '*failed*') {#
    #Write-Host "Task failed"
    #Write-Host "Task finished time : $($taskExtendedInfo.FinishedTime)"
    #& "C:\Zabbix\zabbix_sender.exe" -z 10.5.5.254 -p 10055 -s $env:ComputerName -k job_aum_status -o '0'#
#}

#else {#
    #Write-Host "successful"
    #Write-Host "Task finished time : $($taskExtendedInfo.FinishedTime)"
    #& "C:\Zabbix\zabbix_sender.exe" -z 10.5.5.254 -p 10055 -s $env:ComputerName -k job_aum_status -o '1'#
#}#

if ($taskExtendedInfo.StartTime.Equals("mm") -gt "30") {#
   Write-Host "Task executed after deadline"} else  {
   Write-Host "Task executed OK!"
   & "C:\Zabbix\zabbix_sender.exe" -z 127.0.0.1 -p 10055 -s $env:ComputerName -k job_name_status -o '1'

}



#if (((Get-Date).TimeOfDay - ([datetime]$taskExtendedInfo.FinishedTime).TimeOfDay).TotalMinutes -gt 30 ){ 
    #Write-Host "Task executed after deadline"
    #& "C:\Zabbix\zabbix_sender.exe" -z 10.5.5.254 -p 10055 -s $env:ComputerName -k job_aum_status -o '0'
#} else  {
    #Write-Host "Task executed OK!"
    
#}


#else {
    #Write-Host "successful"
    #Write-Host "Task finished time : $($taskExtendedInfo.FinishedTime)"
    #& "C:\Zabbix\zabbix_sender.exe" -z 10.5.5.254 -p 10055 -s $env:ComputerName -k job_aum_status -o '1'
#}
    