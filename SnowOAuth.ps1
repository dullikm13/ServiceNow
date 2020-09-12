#For getting access token you can use this code:
#edit

$username = “Spevin”

$password = 'Spevin'

$ClientID = “fb63309f8f8b10105ef8dbe88004a7be”

$ClientSecret = “lL{nJh;H<;”


$RestEndpoint = ‘https://dev60556.service-now.com/oauth_token.do’

$body = [System.Text.Encoding]::UTF8.GetBytes(‘grant_type=password&username=’+$username+’&password=’+$password+’&client_id=’+$ClientID+’&client_secret=’+$ClientSecret)

$result = Invoke-RestMethod -Uri $RestEndpoint -Body $Body -ContentType ‘application/x-www-form-urlencoded’ -Method Post

$access_token = $result.access_token


#Once you have access token, you can utilize the invoke-restmethod to fetch data from servicenow : 

$URI = ‘https://dev60556.service-now.com/api/now/table/incident?sysparm_limit=1’
$headers = @{“authorization” = “Bearer $access_token”}

$result = Invoke-RestMethod -Uri $URI -Headers $headers
$result 