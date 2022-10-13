# Mintacoin

![banner][banner-img]

[**Mintacoin**][www] is a minimalist and open-source API, that abstracts the blockchain complexity providing a simple and reliable infrastructure layer to mint your crypto assets, in addition to process payments with them, for you and your company.

Abstracting the blockchain complexity away, and combining the power of [Elixir][elixir] and [Stellar][stellar], Mintacoin aims to help developers adopting Web3.0 and crypto technologies in their solutions. Scaling down the costs, time and technical complexity around the crypto assets market.

Reach the power of blockchain with just an API integration!

## What can you do with Mintacoin?

- Create Mintacoin accounts.
- Create custom crypto assets.
- Process payments with assets.


## Roadmap
The latest updated branch to target a PR is v0.3

You can see a big picture of the roadmap here: [**ROADMAP**][roadmap]
### In progress - What we're working on now 🛠️

- [Assets feature](https://github.com/kommitters/mintacoin/issues/34)
- [Dockerize local setup](https://github.com/kommitters/mintacoin/issues/53)

### Todo - What we're working on next! 🪐

- [Code refactor and improvement](https://github.com/kommitters/mintacoin/issues/55)
- [Payments feature](https://github.com/kommitters/mintacoin/issues/66)

### Done - What we've already developed! 🚀

<details>
<summary>Click to expand!</summary>

 - [Implement the cipher service module](https://github.com/kommitters/mintacoin/issues/9)
 - [Implement the keypair service module](https://github.com/kommitters/mintacoin/issues/10)
 - [Implement the accounts database boundaries and functions](https://github.com/kommitters/mintacoin/issues/11)
 - [Implement the blockchains database boundaries and functions](https://github.com/kommitters/mintacoin/issues/15)
 - [Implement the wallets database boundaries and functions](https://github.com/kommitters/mintacoin/issues/17)
 - [Implement the blockchain tx database boundaries and functions](https://github.com/kommitters/mintacoin/issues/18)
 - [Create the crypto module for stellar (Mocked)](https://github.com/kommitters/mintacoin/issues/21)
 - [Implement the accounts aggregate functions](https://github.com/kommitters/mintacoin/issues/22)
 - [Create the accounts worker](https://github.com/kommitters/mintacoin/issues/23)
 - [Implement the account creation function with the stellar SDK](https://github.com/kommitters/mintacoin/issues/25)
 - [Implement the endpoint to create an account and recover signature](https://github.com/kommitters/mintacoin/issues/31)

</details>

## Want to jump in?

Check out our [Good first issues][good-first-issues], this is a great place to start contributing if you're new to the project!

We welcome contributions from anyone! Check out our [contributing guide][contributing] for more information.

## API REST

You can find the API documentation here: [API DOCUMENTATION][api-documentation]


## Development

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Run the tests with `mix test`.

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
[elixir]: https://elixir-lang.org/
[stellar]: https://stellar.org/
[roadmap]:https://github.com/orgs/kommitters/projects/6/views/6
[good-first-issues]: https://github.com/kommitters/mintacoin/issues?q=is%3Aissue+is%3Aopen+label%3A%22%F0%9F%91%8B+Good+first+issue%22
[api-documentation]: https://docs.mintacoin.co
[changelog]: https://github.com/kommitters/mintacoin/blob/main/CHANGELOG.md
[coc]: https://github.com/kommitters/mintacoin/blob/main/CODE_OF_CONDUCT.md
[contributing]: https://github.com/kommitters/mintacoin/blob/main/CONTRIBUTING.md
[license]: https://github.com/kommitters/mintacoin/blob/main/LICENSE
