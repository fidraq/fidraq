# Variables: session
GET {{base_url}}/api/rest/version/100/merchant/{{merchant_id}}/session/{{session}}
[BasicAuth]
merchant.{{merchant_id}}: {{api_password}}
