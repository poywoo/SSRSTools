<#
.SYNOPSIS
    Deletes an RDL file or folder from SQL Reporting Server using Web Service Proxy
 
.DESCRIPTION
    Deletes an RDL file or folder from SQL Reporting Server using an existing Web Service Proxy or creates a new one using the ReportServerUri param

.PARAMETER RsFolder
    The reporting services folder in which the report is found. If attempting to delete an entire folder and not a singular report, leave the -RsReport parameter blank.

.PARAMETER RsReport
    The reporting services report which will be deleted. The name may be appended with ".rdl" or not. 
    If attempting to delete an entire folder and not a singular report, leave the -RsReport parameter blank.

.PARAMETER ReportServerUri
     Your report server web service url. It will be in the format of "http://[ServerName:Port]/ReportServer". 
     If SSRSProxy parameter is supplied, SSRSProxy will take precedence.

.PARAMETER ApiVersion
    Specifies the Report Server Web service endpoint. Default "2010" for SQL Server 2008 and above.
    The ReportService2005 and ReportService2006 endpoints are deprecated in SQL Server 2008 R2. 
    The ReportService2010 endpoint includes the functionalities of both endpoints and contains additional management features.

.PARAMETER SSRSProxy
    Web Service Proxy object. Use "Create-RsWebServiceProxy" to generate a proxy object for multiple uses. 
    If not suplied, a new web service proxy object is created from ReportServerUri and ApiVersion parameters.
 
.EXAMPLE
    Delete-RsReport -RsFolder "Scheduled Reports" -RsReport "DailyReport" -ReportServerUri "http://[ServerName]:8080/ReportServer" 
    
    Description
    -----------
    Deletes DailyReport from Scheduled Reports folder (/Scheduled Reports/DailyReport) on the SQL Server Reporting Services Instance at "http://[ServerName]:8080/ReportServer"

.EXAMPLE
    Delete-RsReport -RsFolder "Scheduled Reports" -RsReport "DailyReport.rdl" -ReportServerUri "http://[ServerName]:8080/ReportServer" 
    
    Description
    -----------
    Deletes DailyReport from Scheduled Reports folder (/Scheduled Reports/DailyReport) on the SQL Server Reporting Services Instance at "http://[ServerName]:8080/ReportServer"
 
.EXAMPLE
    Delete-RsReport -RsFolder "Scheduled Reports" -ReportServerUri "http://[ServerName]:8080/ReportServer"
    
    Description
    -----------
    Deletes entire Scheduled Reports folder (/Scheduled Reports) on the SQL Server Reporting Services Instance at "http://[ServerName]:8080/ReportServer"
    
.EXAMPLE
    $Proxy = New-WebServiceProxy -Uri "http://[ServerName]:8080/ReportServer/ReportService2010.asmx" -UseDefaultCredential 
    Delete-RsReport -RsFolder "Scheduled Reports" -SSRSProxy $Proxy
    
    Description
    -----------
    Deletes entire Scheduled Reports folder (/Scheduled Reports) using existing web service proxy $Proxy     
#>
function Delete-RsReport (
    [cmdletbinding()]

    [Alias("folder")]
    [string]$RsFolder="",

    [Alias("report")]
    [string]$RsReport="",

    [Alias("url")]
    [string]$ReportServerUri,

    [ValidateSet("2005","2006","2010")]
    [string]$ApiVersion = "2010",

    $SSRSProxy
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
        #Create report or folder path 
        if ($RsFolder -notlike "/*")
            {
                $RsFolder = "/" + $RsFolder 
            }
        if ($RsReport)
        {
            if ($RsReport -like "*.rdl") {
                $RsReport = $RsReport.Substring(0,$RsReport.LastIndexOf("."))
            }
            if ($RsFolder -ne "/")
            {
            $RsReport = "/" + $RsReport
            }      
        }
        $RsPath = $RsFolder + $RsReport

        try 
        {
            Write-Verbose "[Delete-RsReport()] Deleting '$RsPath'..."
            $SSRSProxy.DeleteItem($RsPath)
            Write-Verbose "[Delete-RsReport()] '$RsPath' successfully deleted"
        }
        catch 
        {
            throw (New-Object System.Exception("Exception occurred while attempting to delete'$item': $($_.Exception.Message)", $_.Exception))
        }
    
    }
        
}