<#
.SYNOPSIS
    Compares and syncs a folder on SQL Reporting Server to a local folder.
 
.DESCRIPTION
    Compares and syncs a folder on SQL Reporting Server to a local folder. 

.PARAMETER $ReportFolderPath
    The path to your local report folder

.PARAMETER RsFolder
    The reporting services folder you wish to upload the reports.

.PARAMETER ReportServerUri
     Your report server web service url. It will be in the format of "http://[ServerName:Port]/ReportServer". If SSRSProxy parameter is supplied, SSRSProxy will take precedence. 
     If not suplied, a new web service proxy object is created from ReportServerUri and ApiVersion parameters.

.PARAMETER ApiVersion
    Specifies the Report Server Web service endpoint. Default "2010" for SQL Server 2008 and above.
    The ReportService2005 and ReportService2006 endpoints are deprecated in SQL Server 2008 R2. 
    The ReportService2010 endpoint includes the functionalities of both endpoints and contains additional management features.
 
.EXAMPLE
    Sync-RsFolder -ReportFolderPath "C:\Reports\DBA Reports" -RsFolder "DBA Reports" -ReportServerUri "http://[ServerName]:8080/ReportServer"

    Description
    -----------
    Syncs "DBA Reports" folder on the SQL Server Reporting Services Instance at "http://[ServerName]:8080/ReportServer" to the reports in the local folder at "C:\Reports\DBA Reports"
 
#>
function Sync-RsFolder (
    [cmdletbinding()]

    [ValidateScript({Test-Path $_})]
    [Parameter(Mandatory=$true)]
    [Alias("LocalFolder")]
    [string]$ReportFolderPath,

    [Alias("Folder")]
    [string]$RsFolder="",

    [Parameter(Mandatory=$true)]
    [string]$ReportServerUri,

    [ValidateSet("2005","2006","2010")]
    [string]$ApiVersion = "2010"
)
{

    #. Source the powershell cmdlets
    . C:\PowerShell\SSRSTools\Add-RsReport.ps1
    . C:\PowerShell\SSRSTools\Delete-RsReport.ps1
    . C:\PowerShell\SSRSTools\Create-RsWebServiceProxy.ps1

    # From files on local directory, create hashtable of file name, byte size
    $LocalDirHashTable = @{}
    Get-ChildItem -Path $ReportFolderPath -Recurse | Select-Object Name,Length | ForEach-Object {$LocalDirHashTable[$_.Name] = $_.Length} 

    # Prefix folder with /
    if ($RsFolder -notlike "/*")
    {
        $RsFolder = "/" + $RsFolder
    }

    $RsHashTable = @{}
    $rs = Create-RsWebServiceProxy -ReportServerUri $ReportServerUri
    # Check if folder exists on report server
    try 
    {
        $IsFolder = $rs.ListChildren("/", $true) | Where { $_.TypeName -eq "Folder" -and $_.Path -eq $RsFolder}
    }
    catch 
    {
        throw
    }

    if ($IsFolder)
    {
        foreach ($item in $RsFolder)  
        {
            try 
            {
                $rs.ListChildren($item, $true) |
                            Where-Object { $_.TypeName -eq 'Report' } |  
                            ForEach-Object {$RsHashTable[$_.Name + '.rdl'] = $_.Size} # From files on report server, create hashtable of file name, byte size
            }
            catch 
            {
                throw
            }
        }
    }

    [System.Collections.ArrayList]$New = @($LocalDirHashTable.Keys | Where-Object {($_ -notin $RsHashTable.Keys)}) # Get reports that are in the local directory that are not in the report server
    [System.Collections.ArrayList]$Deleted = @($RsHashTable.Keys | Where-Object {($_ -notin $LocalDirHashTable.Keys)}) #Get reports are that not in the local directory that are in the report server
    [System.Collections.ArrayList]$Modified = @()
    $Matched = $LocalDirHashTable.Keys | Where-Object {($_ -in $RsHashTable.Keys)}    

    foreach ($Report in $Matched) {
        if ($LocalDirHashTable[$Report] -ne $RsHashTable[$Report]){
            $Modified.Add($Report)
        }
    }

    if ($New) 
    {
        Write-Verbose "[Sync-RsFolder()] Adding new reports to reporting server..."
        
        $New | ForEach-Object {
            $rdlFilePath = $ReportFolderPath + "\" + $_
            Add-RsReport -rdl $rdlFilePath -RsFolder $RsFolder -SSRSProxy $rs -Force
        }

        Write-Verbose "[Sync-RsFolder()] New reports successfully added"
    }
    else 
    {
        Write-Verbose "[Sync-RsFolder()] No new reports to add to reporting server"
    }
    
    if ($Modified) 
    {
        Write-Verbose "[Sync-RsFolder()] Adding modified reports to reporting server..."

        $Modified | ForEach-Object {
            $rdlFilePath = $ReportFolderPath + "\" + $_
            Add-RsReport -rdl $rdlFilePath -RsFolder $RsFolder -SSRSProxy $rs -Force
        }

        Write-Verbose "[Sync-RsFolder()] Modified reports successfully added"
    }
    else 
    {
        Write-Verbose "[Sync-RsFolder()] No modified reports to add to reporting server"
    }
    
    if ($Delete) 
    {
        Write-Verbose "[Sync-RsFolder()] Deleting reports from reporting server..."

        $Deleted | ForEach-Object {
            Delete-RsReport -RsFolder $RsFolder -RsReport $_ -SSRSProxy $rs
        }

        Write-Verbose "[Sync-RsFolder()] Reports successfully deleted"

    }
    else 
    {
        Write-Verbose "[Sync-RsFolder()] No reports to delete from reporting server"
    }

    #Write summary of files changed
    $NewCount = $new.Count
    Write-Output "Add: $NewCount Reports" 
    $New | Sort-Object | ForEach-Object {
        Write-Output $_
    }

    Write-Output "`r`n"

    $ModifiedCount = $Modified.Count
    Write-Output "Modify: $ModifiedCount Reports" 
    $Modified | Sort-Object | ForEach-Object {
        Write-Output $_
    }

    Write-Output "`r`n"

    $DeletedCount = $Deleted.Count
    Write-Output "Delete: $DeletedCount Reports" 
    $Deleted | Sort-Object | ForEach-Object {
        Write-Output $_
    }
}