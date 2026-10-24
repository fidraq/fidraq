# Variables: order, transaction (the one used to initiate authentication), session, amount, currency, return_url
PUT {{base_url}}/api/rest/version/100/merchant/{{merchant_id}}/order/{{order}}/transaction/{{transaction}}
[BasicAuth]
merchant.{{merchant_id}}: {{api_password}}
{
  "apiOperation": "AUTHENTICATE_PAYER",
  "authentication": {
    "redirectResponseUrl": "{{return_url}}"
  },
  "device": {
    "browser": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "browserDetails": {
      "3DSecureChallengeWindowSize": "FULL_SCREEN",
      "acceptHeaders": "application/json",
      "colorDepth": 24,
      "javaEnabled": true,
      "language": "en-US",
      "screenHeight": 1080,
      "screenWidth": 1920,
      "timeZone": -180
    },
    "ipAddress": "127.0.0.1"
  },
  "order": {
    "amount": "{{amount}}",
    "currency": "{{currency}}"
  },
  "session": {
    "id": "{{session}}"
  }
}
