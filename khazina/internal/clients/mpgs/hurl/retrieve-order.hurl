# Variables: order
GET {{base_url}}/api/rest/version/100/merchant/{{merchant_id}}/order/{{order}}
[BasicAuth]
merchant.{{merchant_id}}: {{api_password}}
