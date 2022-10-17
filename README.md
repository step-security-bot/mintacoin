# Mintacoin

![banner][banner-img]

[**Mintacoin**][www] is a minimalist and open-source API that abstracts the blockchain complexity by providing a simple and reliable infrastructure layer to mint your crypto assets and process payments with them.

Reach the power of blockchain with just an API integration!

## What can you do with Mintacoin?

Mintacoin will provide endpoints so you can:
- Create accounts.
- Create crypto assets.
- Process payments.

All of this on **multiple blockchains** using a single account, just worrying about two keys we'll give you: an **address** and a **signature**. 👌

## Motivation

The adoption of Web3 implies technical knowledge specific to each technology, ecosystem or protocol. This results in:

- High technical complexity.
- Time and effort.
- Slow time to market, therefore high development costs.

Mintacoin aims to solve these current Web3 issues!

## Why Mintacoin?

It's clear that Web3 needs additional infrastructure layers that facilitate the user experience (UX) in the use of blockchain technologies.

Mintacoin offers a simple and reliable infrastructure layer, so people can focus on their core business and not on the issues mentioned above. 🚀

## What do we want to achieve?

- Make straightforward the adoption of Web3 technologies for developers by proposing interaction with a REST API rather than a blockchain.

- Reduce technical complexity, costs, and time to the market for solutions around crypto assets.

## Documentation

Mintacoin's documentation is available here: [docs.mintacoin.co](https://docs.mintacoin.co)

## Roadmap
The current release for the project is the version [**v0.2.2**][current-release].

To know the current status of the project, you can check Mintacoin's roadmap here: [**ROADMAP**][roadmap] 🗺️


**Do you want to contribute Mintacoin ?**

We really appreciate your interest and effort in Mintacoin's advance and support, check out our [contributing guide][contributing] before the coding.

If you want to contribute to Mintacoin, the latest target branch to submit a PR is the [**branch v0.3**][latest-branch].

Check out our [Good first issues][good-first-issues], this is a great place to start contributing if you're new to the project!

---

## Development

Here we will show up the Mintacoin's setup for development purposes, follow the next steps:

**Requirements**

- Elixir <= v1.14
- Erlang <= 24.3
- PostgreSQL >= v14 (latest)

**Setting up**

1. Install dependencies with:

    `mix deps.get`

2. Mintacoin requires a development configuration file. Copy the example with the following command:

    `cp config/dev.exs.example config/dev.exs`

3. Within the file `dev.exs` replace the following variables

    - `"STELLAR_FUND_SECRET_KEY` with the secret key created from the [Stellar Laboratory][stellar-laboratory].
    - `"BLOCKCHAINS_NETWORK"` with `"testnet"`
    - `"API_TOKEN"` with `"any_api_token_value"`

4. Create and migrate your database with:

    `mix ecto.setup`

5. Run the project in a terminal with `iex -S mix` and add the next record with:

    `Mintacoin.Blockchains.create(%{name: "stellar", network: "testnet"})`

6. Finally, start the Phoenix server with:

    `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Run the tests with `mix test`.

---

## Changelog

Features and bug fixes are listed in the [CHANGELOG][changelog] file.

## Code of conduct

We welcome everyone to contribute. Make sure you have read the [CODE_OF_CONDUCT][coc] before.

## Contributing

For information on how to contribute, please refer to our [CONTRIBUTING][contributing] guide.

## License

This library is licensed under an MIT license. See [LICENSE][license] for details.

## Acknowledgements

Made with 💙 by [kommitters Open Source](https://kommit.co)

[banner-img]: https://user-images.githubusercontent.com/1649973/170068587-1b4c1b0d-9b48-46d1-9aed-f99d1b2b84f8.png
[www]: https://mintacoin.co
[roadmap]:https://github.com/orgs/kommitters/projects/6/views/6
[good-first-issues]: https://github.com/kommitters/mintacoin/issues?q=is%3Aissue+is%3Aopen+label%3A%22%F0%9F%91%8B+Good+first+issue%22
[api-documentation]: https://docs.mintacoin.co
[current-release]: https://github.com/kommitters/mintacoin/releases/tag/v0.2.2
[latest-branch]: https://github.com/kommitters/mintacoin/tree/v0.3
[stellar-laboratory]: (https://laboratory.stellar.org/#account-creator?network=test)
[changelog]: https://github.com/kommitters/mintacoin/blob/main/CHANGELOG.md
[coc]: https://github.com/kommitters/mintacoin/blob/main/CODE_OF_CONDUCT.md
[contributing]: https://github.com/kommitters/mintacoin/blob/main/CONTRIBUTING.md
[license]: https://github.com/kommitters/mintacoin/blob/main/LICENSE
