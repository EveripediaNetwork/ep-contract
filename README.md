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

# Expalaining How BrainPassCollectibles Contract Works

BrainPassCollectibles is a Solidity smart contract that enables the creation and management of BrainPass NFTs. It allows users to buy passes to have some Wiki privileges on IQ Wiki and provides functionalities to mint NFTs, increase pass time, and manage pass types.

## Usage

### Contract Deployment
Deploy the `BrainPassCollectibles` contract by providing the address of the IQ token and the `baseTokenURI` contract as constructor parameters.

## `pause()`
Pauses the contract and prevents any further actions. Can only be called by the contract owner.

## `unpause()`
Unpauses the contract and resumes normal operations. Can only be called by the contract owner.

## `configureMintLimit()`
Configures the lower and upper limits for minting NFTs.
- `lowerLimit`: Minimum duration (in days) for a subscription.
- `upperLimit`: Maximum duration (in days) for a subscription.
Only the contract owner can call this function.

## `addPassType()`
Adds a new pass type.
- `pricePerDay`: Price per day of the new pass type.
- `name`: Name of the new pass type.
- `maxTokens`: Total number of tokens in the pass.
Only the contract owner can call this function and only when the contract is not paused 

## `togglePassTypeStatus()`
toggles the status of a specific pass type from paused to unpaused.
- `passId`: ID of the pass type to be deactivated.
Only the contract owner can call this function and only when the contract is not paused 

## `mintNFT()`
Mints an NFT of a particular pass type.
- `passId`: ID of the pass type to mint.
- `startTimestamp`: Time when the NFT subscription starts.
- `endTimestamp`: Time when the NFT subscription ends.
Can call this function  only when the contract is not paused, using  the `whenNotPaused` modifier 

## `increaseEndTime()`
Increases the EndTime time of an NFT.
- `tokenId`: ID of the NFT whose time is to be increased.
- `newEndTime`: New subscription end time for the NFT.
Only when the contract is not paused can this function be called, using  the `whenNotPaused` modifier

## `withdrawEther()`
Withdraws any amount of Ether held in the contract. 
- `receiver`: The address the Ether would be sent to.
- `amount`: The amount to be sent to the address from the contract.
Only the contract owner can call this function.


## `withdrawIQ()`
Withdraws any amount of IQ tokens held in the contract. 
- `receiver`: The address the Ether would be sent to.
- `amount`: The amount to be sent to the address from the contract.
Only the contract owner can call this function.

## `setBaseURI`
sets the BaseUri in the contructor, during deployment of the contract.

## `_baseURI`
Returns the baseUri of the all tokens

## `getUserPassDetails()`
Retrieves the details of an NFT owned by a specific user for a given pass type.
- `user`: Address of the user.

## `getAllPassType()`
Retrieves the details of all the pass types added to the contract.

## `getPassType()`
Retrieves the details of a specific pass type.
- `passId`: ID of the pass type

## Events

The contract emits the following events:

- `BrainPassBought`: Emitted when a user buys a BrainPass NFT.
- `PassTimeIncreased`: Emitted when the time of a BrainPass NFT is increased.
- `NewPassAdded`: Emitted when a new pass type is added.
- `PassTypeStatusToggled`: Emitted when a pass is paused or unpaused.

## PICTORAL EXPLANATION
![image](https://github.com/EveripediaNetwork/ep-contract/assets/75235148/eee4d631-28d9-4ca4-bc0e-62e5a02998a2)


# Expalaining How BrainPassValidiator Contract Works
BrainPassValidiator is a Solidity smart contract that validates a user to have the ability to post a wiki on IQ Wiki.


## Usage

### Contract Deployment
Deploy the `BrainPassValidiator` contract by providing the address of the BrainPassCollectibles as a constructor parameter.

## `validate()`
`user`: The user address that is validated
Checks the validity of an address and returns a boolean values based on the result.

