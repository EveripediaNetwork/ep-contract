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

BrainPassCollectibles is a Solidity smart contract that enables the creation and management of BrainPass NFTs. It allows users to buy passes to have some Wiki privileges on IQ Wiki and provides functionalities to mint NFTs, increase pass time, and manage pass types.

## Usage

### Contract Deployment
Deploy the `BrainPassCollectibles` contract by providing the address of the IQ token contract as a constructor parameter.

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
- `tokenUri`: URI that stores the data of all the NFTs in the new pass.
- `name`: Name of the new pass type.
- `maxTokens`: Total number of tokens in the pass.
- `discount`: Discount amount (in percentage) to be deducted when buying the pass.
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
Can call this function  only when the contract is not paused 

## `increaseEndTime()`
Increases the EndTime time of an NFT.
- `tokenId`: ID of the NFT whose time is to be increased.
- `newEndTime`: New subscription end time for the NFT.
Only when the contrasct is not paused can this function be called.

## `withdrawEther()`
Withdraws any amount of Ether held in the contract. Can only be called by the contract owner.

## `withdrawIQ()`
Withdraws any amount of IQ tokens held in the contract. Can only be called by the contract owner.

## `getUserPassDetails()`
Retrieves the details of an NFT owned by a specific user for a given pass type.
- `user`: Address of the user.
- `passId`: ID of the pass type.

## `getAllPassType()`
Retrieves the details of all the pass types added to the contract.

## `getPassType()`
Retrieves the details of a specific pass type.
- `passId`: ID of the pass type

## Events

The contract emits the following events:

- `BrainPassBought`: Emitted when a user buys a BrainPass NFT.
- `TimeIncreased`: Emitted when the time of a BrainPass NFT is increased.
- `NewPassAdded`: Emitted when a new pass type is added.
- `PassTypePaused`: Emitted when a pass is paused.

## PICTORAL EXPLANATION
![image](https://github.com/EveripediaNetwork/ep-contract/assets/75235148/eee4d631-28d9-4ca4-bc0e-62e5a02998a2)

# Token ID Assignment Scenario

In this scenario, we will discuss how token IDs are assigned when adding new PassTypes to a system. The goal is to ensure a single ID counter for all tokens while maintaining unique IDs for each PassType.

## OleanjiPass

Existing PassType: OleanjiPass
- Name: "OleanjiPass"
- Max Tokens: 10
- Last Token Minted: 0
- Current NFT Count: 10

For the OleanjiPass PassType, the last token that was minted has an ID of 10, and there are currently a total of 10 tokens minted for this PassType.

## KesarPass

New PassType: KesarPass
- Name: "KesarPass"
- Max Tokens: 15
- Last Token Minted: 10
- Current NFT Count: 25

Since the last token minted for OleanjiPass is 10, we want to start counting the tokens for KesarPass from where OleanjiPass left off.

For the KesarPass, if a token is minted, it will have an ID of 11 since it follows the lastTokenMinted of OleanjiPass, which was 10. The currentNftCount for KesarPass will be updated to 25, indicating that there are now a total of 25 tokens minted for this PassType.

Therefore, the token IDs for KesarPass will range from 11 to 25. The corresponding URLs for these tokens would be as follows:

- [https://oleanjiPass.com/1](https://oleanjiPass.com/1)
- [https://oleanjiPass.com/2](https://oleanjiPass.com/2)
- ...
- [https://oleanjiPass.com/10](https://oleanjiPass.com/10)
- [https://KesarPass.com/11](https://KesarPass.com/11)
- [https://KesarPass.com/12](https://KesarPass.com/12)
- ...
- [https://KesarPass.com/25](https://KesarPass.com/25)

The JSON file for the token data of KesarPass will start from an ID of 11 and go up to 25, reflecting the corresponding token information for each ID.

This approach allows for a consistent numbering sequence across different PassTypes while maintaining unique IDs for each PassType's tokens.

