
param (

    $swaggerSourceUrl,                              # this is API url from where swagger file will be downloaded 
    $APIMResourceGroup, 
    $APIMName,
    $backEndUrl, 
    $swaggerTitle,                                  # This will be reflected in APIM as display name
    $uIUrl,                                         # This is UI URL used for CORS policy 
    $ApiId                                          # This is unique Api Name from APIM where you want to add or update API Operation 
)

# Download the swagger file from the API URL. 
curl $swaggerSourceUrl -o swagger.json 

# below command replace title object in swagger file with the parameter passed 
$jsoncontent = get-content -path .\swagger.json | ConvertFrom-Json 
$jsoncontent.info.title = $swaggerTitle
$jsoncontent | ConvertTo-json -Depth 100 |out-file .\swagger.json -force 

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $APIMResourceGroup -ServiceName $APIMName
Import-AzApiManagementApi -Context $ApiMgmtContext -SpecificationPath ".\swagger.json" -Path "<PathAPIM>" -SpecificationFormat OpenApiJson -Serviceurl $backEndUrl -ApiId $ApiId

# Add policy if any 
$policyString = "
    <policies>
        <inbound>
            <base />
            <cors allow-credentials=`"true`">
            <allowed-origins>
                <origin>$uIUrl</origin>
            </allowed-origins>
            <allowed-methods>
                <method>*</method>
            </allowed-methods>
            <allowed-headers>
                <header>*</header>
            </allowed-headers>
            </cors>
        </inbound>
        <backend>
            <base />
        </backend>
        <outbound>
            <base />
        </outbound>
        <on-error>
            <base />
        </on-error>
    </policies>
"
# Set the policy 
Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId $ApiId -Policy $PolicyString

# get the api context 
$api = Get-AzApiManagementApi -Context $ApiMgmtContext -ApiId $ApiId

# set subscriptionRequired to false in case you want to. else you can skip this setting 
$api.SubscriptionRequired=$false
Set-AzApiManagementApi -InputObject $api
