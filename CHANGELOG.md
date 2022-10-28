# Changelog

## 0.3.1 (28.10.2022)
* Bump ossf/scorecard-action to v2.0.6.

## 0.3.0 (27.10.2022)
* Add asset and asset_holder tables and database functions.
* Add balance table for wallets.
* Add `stellar_sdk` implementation to create an asset in the Stellar network.
* Add `stellar_sdk` implementation to create an trustline in the Stellar network.
* Add oban worker to process the asset creation in the blockchain.
* Add oban worker to process the trustline creation for an account in the blockchain.
* Add endpoints for the assets features; Asset creation, query, and associations.
* Add endpoints for the trustline features; Trustline creation and query associated assets to an account.
* Add bearer token authorization.
* Remove regex validation for UUID.
* Refactor of `stellar_sdk` implementation to create an account.
* Add coverage report using Coveralls.
* Update event target in CD workflow.
* Add API reference documentation for assets and asset holders.
* Add credits in README.

## 0.2.2 (18.10.2022)
* Update README documentation.

## 0.2.1 (11.10.2022)
* Add authorization plug for all endpoints.
* Add deployment files.
* Add continuous deployment workflow file.
* Add API reference documentation.

## 0.2.0 (28.09.2022)
* Add account, wallet, blockchain, and blockchain_tx tables and database functions.
* Add account cipher and keypair services.
* Add `stellar_sdk` implementation to create an account in the Stellar network.
* Add oban worker to process the creation of an account in the blockchain.
* Add endpoint to create an account.
* Add endpoint to retrieve the account's signature with the account's seed words.
* Add Epic task.
* Update PR template.

## 0.1.0 (09.09.2022)
* Initial release
