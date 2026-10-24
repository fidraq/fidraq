# Variables: order, transaction, authentication_transaction, session, amount, currency
PUT {{base_url}}/api/rest/version/100/merchant/{{merchant_id}}/order/{{order}}/transaction/{{transaction}}
[BasicAuth]
merchant.{{merchant_id}}: {{api_password}}
{
  "apiOperation": "PAY",
  "authentication": {
    "transactionId": "{{authentication_transaction}}"
  },
  "order": {
    "amount": "{{amount}}",
    "currency": "{{currency}}",
    "reference": "{{order}}"
  },
  "session": {
    "id": "{{session}}"
  },
  "transaction": {
    "reference": "{{order}}"
  }
}
