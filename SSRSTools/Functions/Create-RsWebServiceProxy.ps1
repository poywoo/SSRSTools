<#
.SYNOPSIS
    Creates a web service proxy object to the Reporting Services Soap endpoint with default credentials
 
.DESCRIPTION
    Creates a web service proxy object to the Reporting Services Soap endpoint with default credentials

.PARAMETER ReportServerUri
     Your report server web service url. It will be in the format of "http://[ServerName:Port]/ReportServer".

.PARAMETER ApiVersion
    Specifies the Report Server Web service endpoint. Default "2010" for SQL Server 2008 and above.
    The ReportService2005 and ReportService2006 endpoints are deprecated in SQL Server 2008 R2. The ReportService2010 endpoint includes the functionalities of both endpoints and contains additional management features.

.EXAMPLE
    Create-RsWebServiceProxy -ReportServerUri "http://[ServerName:Port]/ReportServer" -ApiVersion "2010"
    
    Description
    -----------
    Creates and return a web service proxy to the Report Server located at http://[ServerName:Port]/ReportServer with 2010 endpoint using default credentials.
 
.EXAMPLE
    Create-RsWebServiceProxy -ReportServerUri "http://[ServerName:Port]/ReportServer"
    
    Description
    -----------
    Creates and return a web service proxy to the Report Server located at http://[ServerName:Port]/ReportServer with 2010 endpoint using default credentials.

#>
function Create-RsWebServiceProxy (
    [cmdletbinding()]

    [Parameter(Position=0,Mandatory=$true)]
    [Alias("url")]
    [string]$ReportServerUri,

    [ValidateSet("2005","2006","2010")]
    [string]$ApiVersion = "2010"
)
{
    
    #Create Proxy using default credentials
    if ($ReportServerUri -notlike "*/") 
    {
        $ReportServerUri = $ReportServerUri + "/"
    }
    $ReportServerUri = $ReportServerUri + "ReportService$ApiVersion.asmx"
    try 
    {
        Write-Verbose "[Create-RsWebServiceProxy()] Creating Proxy, connecting to : $ReportServerUri"
        New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential -ErrorAction Stop
    }
    catch 
    {
        throw (New-Object System.Exception("[Create-RsWebServiceProxy()] Failed to establish proxy connection to $ReportServerUri : $($_.Exception.Message)", $_.Exception))
    }
    
}