<#
.SYNOPSIS
    Lists all reports in a SQL Reporting Server folder
 
.DESCRIPTION
    Lists all reports in a SQL Reporting Server folder using an existing Web Service Proxy or creates a new one using the ReportServerUri param

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

.PARAMETER Recurse
    If recurse is specified it will recursively list subfolders with content
 
.EXAMPLE
    Get-RsReports -RsFolder "DBA Reports" -ReportServerUri "http://[ServerName]:8080/ReportServer"
    
    Description
    -----------
    List all reports in the DBA Reports folder at "http://[ServerName]:8080/ReportServer"

.EXAMPLE
    Get-RsReports -RsFolder "DBA Reports" -ReportServerUri "http://[ServerName]:8080/ReportServer" -Recurse

    Description
    -----------
    List all reports in the DBA Reports folder and its subfolders at "http://[ServerName]:8080/ReportServer"
 
.EXAMPLE
    Get-RsReports -RsFolder "DBA Reports" -ReportServerUri "http://[ServerName]:8080/ReportServer" -Recurse | Format-Table -AutoSize

    Description
    -----------
    List all reports in the DBA Reports folder and its subfolders at "http://[ServerName]:8080/ReportServer" and formats it as a table
 
#>
function Get-RsReports (
    [cmdletbinding()]

    [Alias("folder")]
    [string]$RsFolder="",

    [Alias("url")]
    [string]$ReportServerUri,

    [ValidateSet("2005","2006","2010")]
    [string]$ApiVersion = "2010",

    $SSRSProxy,

    [switch]$Recurse
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
    Process 
    {
        #Prefix folder with /
        if ($RsFolder -notlike "/*")
        {
            $RsFolder = "/" + $RsFolder
        }

        try 
        {
            $IsFolder = $rs.ListChildren("/", $true) | Where { $_.TypeName -eq "Folder" -and $_.Path -eq $RsFolder}
            if ($IsFolder)
            {
                foreach ($Item in $RsFolder) 
                {
                    $SSRSProxy.ListChildren($Item, $Recurse) |
                            Where-Object { $_.TypeName -eq "Report" }
                }    
            }
        }
        catch 
        {
            throw
        }
    }
}