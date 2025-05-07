# Yoyo NFT: An NFT collection to make yoga accessible to everyone.

This project consists of a Solidity smart contract designed to manage an NFT collection on the Ethereum blockchain, following the ERC-721 standard and including functionality for minting and transferring non-fungible tokens. The smart contract was written, tested, and deployed in the Foundry development environment.

## Index

1. [Description](#1-description)
2. [Contract Address on Sepolia](#2-contract-address-on-sepolia)
3. [Project Structure](#3-project-structure)
4. [Clone and Configuration](#4-clone-and-configuration)
5. [Technical Choices](#5-technical-choices)
6. [Contributing](#6-contributing)
7. [License](#7-license)
8. [Contacts](#8-contacts)

## 1. Description

Yoyo Nft is a collection of unique NFTs developed and deployed on the Ethereum Sepolia testnet as part of the “Ethereum Advanced” project commissioned by start2impact University.
The project aims at enhancing customers retention of a yoga centre, by giving its first 100 clients a unique NFT which grants exclusive discounts on courses and activities of the centre.
Customers are then able to transfer and exchange their NFTs if they want to, as a sort of reference program for their friends to join the centre.
To fulfill the client's requirements, the minting mechanism of the YoyoNft smart contract has been architected to ensure full randomness, thereby enhancing user engagement and reinforcing the perceived uniqueness and rarity of each NFT. To achieve secure and tamper-proof randomness, the contract integrates Chainlink VRF (Verifiable Random Function), which, as of May 2025, is recognized as the most reliable and widely adopted on-chain solution for generating verifiable random numbers in decentralized applications.

### Constructor:

The constructor requires several input values because this allows for a more modular deployment across different chains. Everything will become clearer during the explanation of the deployment and helperConfig scripts.

### Minting Process:

requestNft() Function
The requestNft() function is responsible for initiating the minting process:
Ensures the user sends at least s_mintPriceEth in msg.value.
Sends a randomness request to the Chainlink VRF Coordinator via requestRandomWords(), with the following parameters:

- keyHash
- subId (Chainlink subscription ID)
- callbackGasLimit
- requestConfirmations = 3
- numWords = 1
- extraArgs.nativePayment = true (enables ETH-native payment)

Maps the returned requestId to the requester's address using s_requestIdToSender.

fulfillRandomWords() Callback
After a minimum of 3 block confirmations, the Chainlink VRF Coordinator automatically invokes the fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) function.

This function handles:

- Validating that the requestId exists in s_requestIdToSender.
- Computing a candidateTokenId using a modulo operation to ensure it's within range.
- If the generated tokenId is already minted, a sequential search is performed via findAvailableTokenId() to find the next available one.
- Marking the tokenId as minted in s_tokensMinted.
- Incrementing the internal counter s_tokenCounter.
- Minting the NFT to the original requester using \_safeMint().
- Dynamically generating and storing the token URI in s_tokenIdToUri.

### Read-Only Functions (Getters)

The YoyoNft smart contract provides several view functions to retrieve information about the NFT collection, ownership, minting status, and contract configuration. These functions can be called without incurring gas costs, as they do not modify the blockchain state.

- tokenURI(uint256 tokenId) → string
  Returns the metadata URI associated with a specific token ID.

- getMyNFT() → uint256[]
  Retrieves an array of token IDs owned by the caller.

- getTotalMinted() → uint256
  Returns the total number of NFTs that have been minted.

- getMintPriceEth() → uint256
  Provides the current mint price required to mint a new NFT, denominated in wei.

- getBaseURI() → string
  Returns the base URI used for constructing the metadata URIs of tokens.

- getSenderFromRequestId(uint256 requestId) → address
  Retrieves the address of the user who initiated a Chainlink VRF request corresponding to the given requestId.

- getOwnerFromTokenId(uint256 tokenId) → address
  Returns the current owner of the specified token ID.

- getAccountBalance(address account) → uint256
  Provides the number of NFTs owned by the specified address.
  Utilizes the standard ERC-721 balanceOf(account) function.

These getter functions facilitate interaction with the YoyoNft contract, allowing users and developers to query essential information about the NFT collection and individual tokens.

## 2. Contract Address on Sepolia

How to Interact with the Contract
The project does not include a frontend. Interactions with the deployed smart contract must be done manually via Etherscan.

Requirements:

- A wallet configured for the Sepolia Ethereum testnet (e.g. MetaMask)
- Some Sepolia ETH
- The deployed contract address on Sepolia

To mint an NFT:

- Go to the deployed contract on Etherscan.
- Open the "Write Contract" section.
- Connect your wallet.
- Call the requestNft() function, sending at least the required mint price in ETH.

## 3. Project Structure

project-root/
├── script/
│ ├── DeployYoyoNft.s.sol
│ ├── HelperConfig.s.sol
│ └── Interactions.s.sol
├── src/
│ └── YoyoNFT.sol
├── test/
│ ├── YoyoNFT.t.sol
│ └── mock/
│ ├── MockLinkToken.sol
│ └── VRFCoordinatorV2PlusMock.sol

### DeployYoyoNft.s.sol

This script deploys our smart contract. It works together with `HelperConfig` and `Interactions` to automate deployment across different chains, as well as to create, fund, and add a consumer to the Chainlink VRF subscription.

### helperConfig.s.sol

This script configures the deployment based on the specific blockchain network being used. It uses conditional `if/else` logic with different `chainId` values to apply custom deployment settings and constructor arguments depending on the target network.
As a result, certain constructor parameters must be provided dynamically to match the network's requirements. For example, the VRF and Link token mocks are only deployed when running on a local test network.
Currently, the script supports two networks: **ANVIL** (Foundry’s local testnet) and **SEPOLIA**. However, it is already structured to allow easy integration of additional networks in the future.

### Interactions.s.sol

This script automates the management of Chainlink VRF V2.5 subscriptions.

- `createSubscription` creates a new subscription using the mock contract when running on a local test network.
- `addConsumer` adds a consumer contract to the subscription, allowing it to use Chainlink VRF.
- `fundSubscription` funds the subscription using mock LINK tokens on a local network, or via `transferAndCall` when on a testnet or mainnet using the official LINK token contract.

All configuration logic is centralized in the `HelperConfig` contract, which handles environment-specific settings.

### YoyoNFT.sol

It is the NFT collection' s contract.

### YoyoNft.t.sol

It is the contract where I perform all the tests.

### LinkToken.sol

It is the mock version of the LINK token contract, and it's used to fund the mock VRF subscription when working in a local test environment.

### VRFCoordinatorV2_5MockWrapped.sol

It is the mock version of the Chainlink VRF contract, which I modified by adding a few functions to make testing easier. I made the `getRequest` function public to access request data that was previously private. I also added `getSubscriptionBalance` to help with debugging.

## 4. Clone and Configuration

1. **Clone the repository**:

   ```bash
   git clone https://github.com/eliab256/Yoyo-NFT-coaching-platform.git
   ```

2. **Navigate into the project directory**:

   ```bash
   cd Yoyo-NFT-coaching-platform
   ```

## 5. Technical Choices

### Languages

- **Solidity**: Chosen both for developing smart contracts on Ethereum and tests in Foundry.

### Tools

- **Foundry**: A development environment for compiling, deploying, testing, and debugging smart contracts.

### Libraries

- **ChainlinkVRF**: The Chainlink VRF library is used in the project to generate secure and verifiable random numbers, which are needed to unpredictably assign tokenIds during the NFT minting phase.

```bash
forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit
```

- **OpenZeppelin**:The OpenZeppelin Contracts library is used to extend the ERC721 contract, the official standard for NFTs on Ethereum, to the current project in order to inherit its features.

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

- **DevOps**: The foundry-devops library is a tool designed to simplify and automate DevOps operations in Foundry projects. In this project, it is used to retrieve the address of the most recently deployed instance of a specific contract by reading data from the broadcast folder. This is useful to avoid hardcoding addresses in your scripts.

```bash
forge install Cyfrin/foundry-devops --no-commit
```

- **Solmate**: It provides a set of standard smart contracts as an alternative to those of OpenZeppelin, but with a strong focus on gas optimization and simplicity. In this project, it is used to simplify the creation of the mock Link token.

```bash
forge install transmissions11/solmate --no-commit
```

## 6. Contributing

Thank you for your interest in contributing to **Yoyo NFT**! Every contribution is valuable and helps improve the project. There are various ways you can contribute:

- **Bug Fixes**: If you find a bug, feel free to submit a fix.
- **Adding New Features**: Propose new features or improvements.
- **Documentation**: Help improve the documentation.
- **Fork**: Fork this project onto other chains.
- **Testing and Refactoring**: Run tests on the code and suggest improvements.

### How to Submit a Contribution

1. **Fork the repository**: Click the "Fork" button to create a copy of the repo.
2. **Clone your fork**:

   ```bash
   git clone  https://github.com/eliab256/Yoyo-NFT-coaching-platform.git
   ```

3. **Create a new branch**:

   ```bash
   git checkout -b branch-name
   ```

4. **Commit your changes**:

   ```bash
   git add .
   git commit -m "Modify description"
   ```

5. **Push your branch and create a pull request**:

   ```bash
   git push origin branch-name
   ```

Final Tips

- **Clarity**: Ensure that the instructions are clear and easy to follow.
- **Test the Process**: If possible, test the contribution process from an external perspective to ensure it flows smoothly.
- **Keep It Updated**: Update this section if the guidelines change or if the project evolves.

## 7. License

This project is licensed under the **MIT License**.

## 8. Contacts

For more information, you can contact me:

- **Project Link**: [GitHub Repository](https://github.com/eliab256/Yoyo-NFT-coaching-platform)
- **Website**: [Portfolio](https://elia-bordoni-blockchain-dev.netlify.app/)
- **Email**: bordonielia96@gmail.com
- **LinkedIn**: [Elia Bordoni](https://www.linkedin.com/in/elia-bordoni/)
