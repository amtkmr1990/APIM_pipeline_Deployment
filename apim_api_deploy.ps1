
param (

    $swaggerSourceUrl,                              # this is API url from where swagger file will be downloaded 
    $APIMResourceGroup = "rg-apiplatform-nonprd", 
    $APIMName = "apim-apiplatform-nonprd",
    $backEndUrl, 
    $swaggerTitle,                                  # This will be reflected in APIM as display name
    $uIUrl,                                         # This is UI URL used for CORS policy 
    $ApiId                                          # This is unique Api Name from APIM where you want to add or update API Operation 
)

curl $swaggerSourceUrl -o swagger.json 
$jsoncontent = get-content -path .\swagger.json | ConvertFrom-Json 
$jsoncontent.info.title = $swaggerTitle
$jsoncontent | ConvertTo-json -Depth 100 |out-file .\swagger.json -force 

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $APIMResourceGroup -ServiceName $APIMName
Import-AzApiManagementApi -Context $ApiMgmtContext -SpecificationPath ".\swagger.json" -Path "external/catalystreactor" -SpecificationFormat OpenApiJson -Serviceurl $backEndUrl -ApiId $ApiId


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
# set subscriptionRequired to false
$api.SubscriptionRequired=$false
Set-AzApiManagementApi -InputObject $api
