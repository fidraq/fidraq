# Variables: session, order, amount, currency
PUT {{base_url}}/api/rest/version/100/merchant/{{merchant_id}}/session/{{session}}
[BasicAuth]
merchant.{{merchant_id}}: {{api_password}}
{
  "order": {
    "amount": "{{amount}}",
    "currency": "{{currency}}",
    "id": "{{order}}"
  }
}
