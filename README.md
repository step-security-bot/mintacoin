# Mintacoin

![banner][banner-img]

[**Mintacoin**][www] is a minimalist and open-source API, that abstracts the blockchain complexity providing a simple and reliable infrastructure layer to mint your crypto assets, in addition to process payments with them, for you and your company.

Abstracting the blockchain complexity away, and combining the power of [Elixir][elixir] and [Stellar][stellar], Mintacoin aims to help developers adopting Web3.0 and crypto technologies in their solutions. Scaling down the costs, time and technical complexity around the crypto assets market.

Reach the power of blockchain with just an API integration!

**Web3.0 issues**

Adopting web3.0 technologies implies technical knowledge, not just regular but specialized to each technology, ecosystem, and protocol, this drift into:

- High technical complexity. 🧐
- Time and effort. ⏳
- The slow market thus high development costs. 📑

**What is the Mintacoin goal ?**

Reduce the adoption rate between developers and web3.0 technologies, through an API REST instead of a blockchain. Besides, this will solve the problems previously mentioned. 🎯

**Why Mintacoin ?**

Is noticeable that Web3.0 needs many infrastructure layers which aid the UX with the usage of blockchain technologies, and Mintacoin provides a simple layer. Amazing right? 🚀

**Who are the Mintacoin users ?**

Software developers. 👩‍💻👨‍💻

**What can you do with Mintacoin?**

- Create Mintacoin accounts. 💳
- Create custom crypto assets. 🪙
- Process payments with assets. 💰

---

## API REST

You can find the API documentation here: [API DOCUMENTATION][api-documentation]

---

## Roadmap
The current release for the project is the version [**v0.2.2**][current-release].

To know the current status of the project, you can check Mintacoin's roadmap here: [**ROADMAP**][roadmap] 🗺️

The following table shows up the tasks created until the moment:

| **Status**          | **Issues** |
| ---                 | ---        |
| **Todo 🛠️**         | [Code refactor and improvement](https://github.com/kommitters/mintacoin/issues/55) <br> [Payments feature](https://github.com/kommitters/mintacoin/issues/66) <br> [Customers feature](https://github.com/kommitters/mintacoin/issues/69) |
| **In progress 🚀**  | [Assets feature](https://github.com/kommitters/mintacoin/issues/34) <br> [Dockerize local setup](https://github.com/kommitters/mintacoin/issues/53) |
| **Done 🪐**         |  <br> [Implement the cipher service module](https://github.com/kommitters/mintacoin/issues/9) <br> [Implement the keypair service module](https://github.com/kommitters/mintacoin/issues/10) <br> [Implement the accounts atabase boundaries and functions](https://github.com/kommitters/mintacoin/issues/11) <br> [Implement the blockchains database boundaries and functions](https://github.com/kommitters/mintacoin/issues/15) <br> [Implement the wallets database boundaries and functions](https://github.com/kommitters/mintacoin/issues/17) <br> [Implement the blockchain tx database boundaries and functions](https://github.com/kommitters/mintacoin/ssues/18) <br> [Create the crypto module for stellar (Mocked)](https://github.com/kommitters/mintacoin/issues/21) <br> [Implement the accounts aggregate functions](https://github.com/kommitters/mintacoin/issues/22) <br> [Create the accounts worker](https://github.com/kommitters/mintacoin/issues/23) <br> [Implement the account creation function with the stellar SDK](https://github.com/kommitters/mintacoin/issues/25) <br> [Implement the endpoint to create an account and recover signature](https://github.com/kommitters/mintacoin/issues/31) |


**Do you want to contribute Mintacoin ?**

We really appreciate your interest and effort in Mintacoin's advance and support, check out our [contributing guide][contributing] before the coding.

If you want to contribute to Mintacoin, the latest target branch to submit a PR is the [**branch v0.3**][latest-branch].

Check out our [Good first issues][good-first-issues], this is a great place to start contributing if you're new to the project!

---

## Development

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

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
[elixir]: https://elixir-lang.org/
[stellar]: https://stellar.org/
[roadmap]:https://github.com/orgs/kommitters/projects/6/views/6
[good-first-issues]: https://github.com/kommitters/mintacoin/issues?q=is%3Aissue+is%3Aopen+label%3A%22%F0%9F%91%8B+Good+first+issue%22
[api-documentation]: https://docs.mintacoin.co
[current-release]: https://github.com/kommitters/mintacoin/releases/tag/v0.2.2
[latest-branch]: https://github.com/kommitters/mintacoin/tree/v0.3
[changelog]: https://github.com/kommitters/mintacoin/blob/main/CHANGELOG.md
[coc]: https://github.com/kommitters/mintacoin/blob/main/CODE_OF_CONDUCT.md
[contributing]: https://github.com/kommitters/mintacoin/blob/main/CONTRIBUTING.md
[license]: https://github.com/kommitters/mintacoin/blob/main/LICENSE
