# Variables: order, transaction, session, currency
PUT {{base_url}}/api/rest/version/100/merchant/{{merchant_id}}/order/{{order}}/transaction/{{transaction}}
{
  "apiOperation": "INITIATE_AUTHENTICATION",
  "authentication": {
    "channel": "PAYER_BROWSER"
  },
  "order": {
    "currency": "{{currency}}"
  },
  "session": {
    "id": "{{session}}"
  }
}
