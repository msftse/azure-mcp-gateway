<policies>
    <inbound>
        <base />
        <validate-jwt header-name="Authorization" 
                      failed-validation-httpcode="401" 
                      failed-validation-error-message="Unauthorized">
            <openid-config url="https://login.microsoftonline.com/${tenant_id}/v2.0/.well-known/openid-configuration" />
            <audiences>
                <audience>https://${function_app_hostname}</audience>
            </audiences>
            <issuers>
                <issuer>https://sts.windows.net/${tenant_id}/</issuer>
            </issuers>
        </validate-jwt>
        <rate-limit calls="100" renewal-period="60" />
        <set-backend-service base-url="https://${function_app_hostname}" />
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
