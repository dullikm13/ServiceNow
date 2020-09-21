#Written by Kevin Dulli on 9/11/2020
##Base script stolen from stackoverflow
##Logic for querying tables and parsing output from Kevin



###############################################
# Configure variable below, you will be prompted for your SNOW login
###############################################
#$SNOWURL = "https://wpshelpdesk.servicenowservices.com/"
$SNOWURL = "https://wpsdevhelpdesk.servicenowservices.com/"
################################################################################
# Nothing to configure below this line - Starting the main function 
################################################################################
###############################################
# Prompting & saving SNOW credentials, delete the XML file created to reset
###############################################
# Setting credential file
$SNOWCredentialsFile = "\\ctx-nasp01\iso-flat\Citrix\Troubleshooting\Dulli\Scripts\PSWIP\SNOWCredentials.xml"
# Testing if file exists
$SNOWCredentialsFileTest =  Test-Path $SNOWCredentialsFile
# IF doesn't exist, prompting and saving credentials
IF ($SNOWCredentialsFileTest -eq $False)
{
$SNOWCredentials = Get-Credential -Message "Enter SNOW login credentials"
$SNOWCredentials | EXPORT-CLIXML $SNOWCredentialsFile -Force
}
# Importing credentials
$SNOWCredentials = IMPORT-CLIXML $SNOWCredentialsFile
# Setting the username and password from the credential file (run at the start of each script)
$SNOWUsername = $SNOWCredentials.UserName
$SNOWPassword = $SNOWCredentials.GetNetworkCredential().Password
##################################
# Building Authentication Header & setting content type
##################################
$HeaderAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $SNOWUsername, $SNOWPassword)))
$SNOWSessionHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$SNOWSessionHeader.Add('Authorization',('Basic {0}' -f $HeaderAuth))
$SNOWSessionHeader.Add('Accept','application/json')
$Type = "application/json"
###############################################
# Getting list of Incidents
###############################################

#The List of active SI-2 Tasks we'll ultimately be populating
$ActiveList = @()

#Loading up the URL that will serve as our initial query to get active tasks assigned to the Citrix team
$TaskListURL = $SNOWURL+"api/now/table/sc_task"
$TaskListURL += "?sysparm_query=assignment_group=1d9a684e610481005d8361c888d72ae7^closed_atISEMPTY&sysparm_limit=100"

#Attempt to make the REST call
Try 
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $TaskListJSON = Invoke-RestMethod -Method GET -Uri $TaskListURL -TimeoutSec 100 -Headers $SNOWSessionHeader -ContentType $Type
    $TaskList = $TaskListJSON.result
}
Catch 
{
    Write-Host $_.Exception.ToString()
    $error[0] | Format-List -Force
}

#Filter the list of active Tasks from above down to those that are from SI-2 Flaw Remediation requests 
foreach($task in $TaskList)
{
    #Some tasks aren't from requests, so skip those.
    if($task.request)
    {
        #Build another query to check the request type that spawned this task 
        $Request = $task.request.value
        $RequestListURL = $SNOWURL+"api/now/table/sc_req_item"
        $RequestListURL += "?sysparm_query=request=$request"
    
        #Make the REST call
        try
        {    
            $RequestListJSON = Invoke-RestMethod -Method GET -Uri $RequestListURL -TimeoutSec 100 -Headers $SNOWSessionHeader -ContentType $Type
            $RequestResult = $RequestListJSON.result
        }
        Catch
        {
            Write-Host $_.Exception.ToString()
            $error[0] | Format-List -Force
        }

        #If the request category is SI 2 Flaw Remediation, add it to the list
        if($RequestResult.cat_item.Value -eq "440762ec0f88020061ec847022050e61")
        {
            $ActiveList += $task
        }
    }
}

#Output filtered list of TASKs that should math the following criteria
##Assigned to Citrix team
##Open
##Spawned from SI 2 Flaw Remediation requests
$ActiveList | Where-Object {$_.active -eq "true"} | Select number,short_description,opened_at,impact,priority | Sort-Object opened_at -Descending | Format-Table

