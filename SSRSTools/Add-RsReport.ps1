<#
.SYNOPSIS
    Uploads an RDL file to SQL Reporting Server using Web Service Proxy
 
.DESCRIPTION
    Uploads an RDL file to SQL Reporting Server using an existing Web Service Proxy or creates a new one using the ReportServerUri param

.PARAMETER rdlFilePath
    The full path of your report (.rdl file).

.PARAMETER RsFolder
    The reporting services folder you wish to upload the report. If -Force parameter is specified, it will create the folder if it does not exist.
    If none is specified, it will upload to root directory.

.PARAMETER ReportServerUri
     Your report server web service url. It will be in the format of "http://[ServerName:Port]/ReportServer". If SSRSProxy parameter is supplied, SSRSProxy will take precedence. 
     If not suplied, a new web service proxy object is created from ReportServerUri and ApiVersion parameters.

.PARAMETER ApiVersion
    Specifies the Report Server Web service endpoint. Default "2010" for SQL Server 2008 and above.
    The ReportService2005 and ReportService2006 endpoints are deprecated in SQL Server 2008 R2. 
    The ReportService2010 endpoint includes the functionalities of both endpoints and contains additional management features.

.PARAMETER SSRSProxy
    Web Service Proxy object. Use "Create-RsWebServiceProxy" to generate a proxy object for multiple uses.

.PARAMETER Force
    If force is specified it will create the report folder if not existing and overwrite the report if existing.
 
.EXAMPLE
    Add-RsReport -rdlFilePath "C:\Scheduled Reports\Report.rdl" -RsFolder "Scheduled Reports" -ReportServerUri "http://[ServerName]:8080/ReportServer" -Force
    
    Description
    -----------
    Uploads Report.rdl to Scheduled Reports folder on the SQL Server Reporting Services Instance at "http://[ServerName]:8080/ReportServer" with overwrite if the file already exists

.EXAMPLE
    Add-RsReport -rdlFilePath "C:\Scheduled Reports\Report.rdl" -ReportServerUri "http://[ServerName]:8080/ReportServer" -Force

    Description
    -----------
    Uploads Report.rdl to root folder on the SQL Server Reporting Services Instance at "http://[ServerName]:8080/ReportServer" with overwrite if the file already exists
 
.EXAMPLE
    $Proxy = New-WebServiceProxy -Uri "http://[ServerName]:8080/ReportServer/ReportService2010.asmx" -UseDefaultCredential 
    Add-RsReport -rdlFilePath "C:\Scheduled Reports\Report.rdl" -RsFolder "Scheduled Reports" -SSRSProxy $Proxy

    Description
    -----------
    Uploads Report.rdl to Scheduled Reports folder through an existing web service proxy $Proxy without overwrite if the file already exists
 
#>
function Add-RsReport (
    [cmdletbinding()]

    [ValidateScript({Test-Path $_})]
    [Parameter(Mandatory=$true)]
    [Alias("rdl")]
    [string]$rdlFilePath,

    [Alias("folder")]
    [string]$RsFolder="",

    [Alias("url")]
    [string]$ReportServerUri,

    [ValidateSet("2005","2006","2010")]
    [string]$ApiVersion = "2010",

    $SSRSProxy,

    [switch]$Force
)
{
    Begin 
    {
    #. Source the powershell cmdlets. Replace with your file path.
    . C:\Powershell\SSRSTools\Create-RsWebServiceProxy.ps1

    #Create Proxy if one is not passed as a parameter
    if (!$SSRSProxy) {
        $SSRSProxy = Create-RsWebServiceProxy -ReportServerUri $ReportServerUri -ApiVersion $ApiVersion
        }
    }
    Process {
    #if Force, check if folder already exists on SSRS and create if not found 
    $ReportPath = "/"
    if($Force) 
        {
            try
            {
                if ($RsFolder -like "/*")
                {
                $RsFolder = $RsFolder.Substring($RsFolder.IndexOf("/")+1)
                } 
                $SSRSProxy.CreateFolder($RsFolder, $ReportPath, $null)
                Write-Verbose "[Add-RsReport()] Created new folder: $RsFolder"
            }
            catch [System.Web.Services.Protocols.SoapException]
            {
                if ($_.Exception.Detail.InnerText -match "[^rsItemAlreadyExists400]")
                {
                    Write-Verbose "[Add-RsReport()] Folder: $RsFolder already exists."
                }
                else
                {
                    $msg = "[Add-RsReport()] Error creating folder: $RsFolder. Msg: '{0}'" -f $_.Exception.Detail.InnerText
                    Write-Error $msg
                }
            }
 
        }

    #Upload report
    try
        {
            $ReportName = [System.IO.Path]::GetFileNameWithoutExtension($rdlFilePath)
            #Get Report content in bytes
            $byteArray = gc $rdlFilePath -encoding byte
            $msg = "[Add-RsReport()] Total file length: {0}" -f $byteArray.Length
            Write-Verbose $msg
            
            if ($RsFolder -notlike "/*")
            {
                $RsFolder = $ReportPath + $RsFolder
            }
            Write-Verbose "[Add-RsReport()] Uploading $ReportName to: $RsFolder"
 
            #Use Proxy to upload report
            $warnings = $null
            $ssrsProxy.CreateCatalogItem("Report",$ReportName,$RsFolder,$Force,$byteArray,$null, [ref]$warnings) | Out-Null
            if ($warnings)
            {
                foreach ($warning in $warnings)
                {
                    Write-Warning $warning.Message
                }
            }
            else
            {
                Write-Verbose "[Add-RsReport()] Upload Success."
            } 
        }
        catch [System.IO.IOException]
        {
            $msg = "[Add-RsReport()] Error while reading rdl file : '{0}', Message: '{1}'" -f $rdlFilePath, $_.Exception.Message
            Write-Error msg
        }
        catch [System.Web.Services.Protocols.SoapException]
        {
            $msg = "[Add-RsReport()] Error while uploading rdl file : '{0}', Message: '{1}'" -f $rdlFilePath, $_.Exception.Detail.InnerText
            Write-Error $msg
        }
    }
}