
## REST API

Minimalist API to run your crypto.

### Base URL

Currently, Mintacoin offers a Sandbox URL. Useful for testing and getting started with the API, the transactions are sent to the testnet of the supported blockchains.

```
https://sandbox.api.mintacoin.co
```

### Success response

A success response has the following format:

```javascript
{
  "data": {
      ...
  },
  "status": 200 | 201
}
```

##### Response parameters

| Parameter | Type    | Description                                                  |
| --------- | ------- | ------------------------------------------------------------ |
| `data`    | Map     | Contains the data returned by the endpoint you're accessing. |
| `status`  | Integer | HTTP response status code.                                   |


### Accounts

Group of endpoints to manage the account resource.

An account is the main resource in Mintacoin, because it gives you the keys that allow managing other resources in the API, and it is identified by the `address` field.

#### **Create account**
    
Creates an account on Mintacoin and on the given blockchain.

This endpoint returns the necessary to manage an account in Mintacoin: **address** (Mintacoin public key), **signature** (Mintacoin secret key), and **seed words** (to recover the signature).

##### Example requests

HTTP request:

```http
POST /accounts
```

Curl request:

```bash
curl -X POST \
     -H 'Content-Type: application/json' \
     -d '{"blockchain": "stellar"}' \
     "https://sandbox.api.mintacoin.co/accounts"
```

##### Body params

```json
{
  "blockchain": "stellar"
}
```

| Param        | Description                                                         |
| ------------ | ------------------------------------------------------------------- |
| `blockchain` | The blockchain in which the account's first wallet will be created. |

> Blockchains supported: `stellar`.

##### Response

```json
{
  "data": {
     "address": "D6J2KKOOXSTOXO36REKBPL3QH4FL2PCFKBK6W3TIOVMHR7DDVLTQ",
     "seed_words": "movie enrich merit census grid twice praise return glass wagon yard faint",
     "signature": "DCZIKJFUC6O5R2PVDDPB2C3XFGJL2ZCRKV66WNCPB4UDCP64HQLQ"
  },
  "status": 201
}
```

##### Response data parameters

| Parameter    | Type   | Description                                                                                                 |
| ------------ | ------ | ----------------------------------------------------------------------------------------------------------- |
| `address`    | String | Public key of your Mintacoin account.                                                                       |
| `signature`  | String | Secret key of your Mintacoin account. keep it safe and don't share it.                                      |
| `seed_words` | String | 12 words that you can use to recover your `signature` if you lost it, keep them safe, and don't share them. |

---

#### **Recover signature**
    
Recovers the `signature` with the `address` and the `seed_words` of an account.

##### Example requests

HTTP request:

```http
POST /accounts/:address/recover
```

Curl request:

```bash
curl -X POST \
     -H 'Content-Type: application/json' \
     -d '{"seed_words": "movie enrich merit census grid twice praise return glass wagon yard faint"}' \
     "https://sandbox.api.mintacoin.co/accounts/D6J2KKOOXSTOXO36REKBPL3QH4FL2PCFKBK6W3TIOVMHR7DDVLTQ/recover"
```

##### Body params

```json
{
  "seed_words": "movie enrich merit census grid twice praise return glass wagon yard faint"
}
```

| Param        | Description           |
| ------------ | --------------------- |
| `seed_words` | Account's seed words. |

##### Response

```json
{
  "data": {
     "signature": "DCZIKJFUC6O5R2PVDDPB2C3XFGJL2ZCRKV66WNCPB4UDCP64HQLQ"
  },
  "status": 200
}
```

##### Response data parameters

| Parameter   | Type   | Description                           |
| ----------- | ------ | ------------------------------------- |
| `signature` | String | Secret key of your Mintacoin account. |

---
    
### Error response

An error response has the following format:

```json
{
 "code": "blockchain_not_found",
 "detail": "The introduced blockchain doesn't exist",
 "status": 400
}
```

##### Response parameters

| Parameter | Type    | Description                                                |
| --------- | ------- | ---------------------------------------------------------- |
| `code`    | String  | Result code of the response that communicates the failure. |
| `detail`  | String  | Description of the error response.                         |
| `status`  | Integer | Status code of the response.                               |

##### Standard error responses

| Code                   | Detail                                  | Status |
| ---------------------- | --------------------------------------- | ------ |
| `blockchain_not_found` | The introduced blockchain doesn't exist | 400    |
| `decoding_error`       | Address or seed words are invalid       | 400    |
| `invalid_address`      | The address is invalid                  | 400    |
| `invalid_seed_words`   | The seed words are invalid              | 400    |
| `encryption_error`     | Error during encryption                 | 400    |
