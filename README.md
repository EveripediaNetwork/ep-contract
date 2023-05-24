# <h1 align="center"> EP CONTRACTS </h1>

**EP CONTRACTS**

## Getting Started

run:

```sh
forge init
forge build
forge test
```

## Testing

```sh
    #test specific function with log
    forge test -vvv -m <functionName>

    #test all functions in a contract
    forge test --match-contract <contractName>

```

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.

## SCRIPTS

Deploy and verify a contract

```sh
# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/BrainPassDeployer.s.sol:BrainPassDeployer --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv --gas-price 60 --legacy

```

# Expalaining How BrainPassCollectibles Works

BrainPassCollectibles is a Solidity smart contract that enables the creation and management of BrainPass NFTs. It allows users to buy passes to have some Wiki previledges on IQ Wiki and provides functionalities to mint NFTs, increase pass time, and manage pass types.

## Usage

### Contract Deployment

Deploy the `BrainPassCollectibles` contract by providing the address of the IQ token contract as a constructor parameter.

### Adding a Pass Type
This function allows the contract owner to add a new pass type.

Call the `addPassType` function with the following parameters:
- `pricePerDay`: The price per day in IQ tokens for the pass.
- `tokenURI`: The base URI for the pass token metadata.
- `name`: The name of the pass type.
- `maxTokens`: The maximum number of tokens that can be minted for this pass type.
- `discount`: The discount percentage applied to the pass price (optional).

### Minting an NFT Pass
This function allows users to mint a BrainPass NFT for a specific pass type and duration.
Call the `mintNFT` function with the following parameters:
- `passId`: The ID of the pass type to mint.
- `startTimestamp`: The start timestamp for the pass.
- `endTimestamp`: The end timestamp for the pass.
- the duration is calculated by endTimestamp - startTimestamp
- An address can only mint one passtype.
- The payment is in IQ Token

### Increasing Pass Time
This function is ued to increase the duration for which a pass is owned for.
Call the `increasePassTime` function with the following parameters:
- `tokenId`: The ID of the NFT whose time should be increased.
- `newStartTime`: The new start timestamp for the pass.
- `newEndTime`: The new end timestamp for the pass.

### Get User Pass Details
This gets the details of the tokenId the user has in the particular passId
Call the `getUserPassDetails` function with the following parameters:
- `user`: The address of the user.
- `passId`: The ID of the pass type.

### Get Pass Types
Call the `getAllPassType` function to get an array of all pass types.

### Get Pass Type Details
This gets a single passtype  details
Call the `getPassType` function with the following parameters:
- `passId`: The ID of the pass type.

### Withdraw Ether
Only the contract owner can call the `withdraw` function to withdraw any amount of Ether stored in the contract. 

## Events

The contract emits the following events:

- `BrainPassBought`: Emitted when a user buys a BrainPass NFT.
- `TimeIncreased`: Emitted when the time of a BrainPass NFT is increased.
- `NewPassAdded`: Emitted when a new pass type is added.


