# Variables: order, transaction
GET {{base_url}}/api/rest/version/100/merchant/{{merchant_id}}/order/{{order}}/transaction/{{transaction}}
[BasicAuth]
merchant.{{merchant_id}}: {{api_password}}
