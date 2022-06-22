# <h1 align="center"> EP CONTRACTS </h1>

**EP CONTRACTS**


## Getting Started

run:
```sh
forge init
forge build
forge test
```

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.


## Deployment

```sh
forge script script/WikiNoValidator.s.sol:WikiNoValidator --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv --gas-price 60 --legacy
```
