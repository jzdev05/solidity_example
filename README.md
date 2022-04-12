# LayerZero Omnichain Contracts

 ### Install & Run tests
```shell
npm install
npx hardhat test 
```

* The examples in the `example` folder are meant for demonstrating LayerZero messaging behaviours. 
* Always audit your own code and test extensively on `testnet` before going to mainnet 🙏

# OmnichainFungibleToken (OFT)

The `OmnichainFungibleToken` has two varieties of deployments:
 1. `BasedOFT.sol` - The token supply is minted at deploy time on the `base` chain. Other chains deploy with 0 supply initially. 
 2. `OFT.sol` - At deploy time, any token supply can be minted on the local chain.    

 For the `BasedOFT` variety, all tokens transferred out of the `base` chain will be locked in the base contract (and minted on destination), and tokens transferred out of `other` chains will be burned on that chain (and minted on destination). This results in the `Base chain` being like the home base. The initial supply will be minted entirely on the `Base Chain` on deployment.
 
In the example deployment below we use `BasedOFT` and the `base` chain is ```rinkeby```.
This setting is configured in ```constants/oftBaseChain.json```.
The `OmnichainFungibleToken` deployed on other chains will use this configuration to set their `base` chain.
Using the Ethereum network ```(testnet: rinkeby)``` as a `base` (really its like the source of truth) is a security decision.
In the event a chain goes rogue, Ethereum will be the final source of truth for OFT tokens.

# Deploy Examples
> Add a .env file with your MNEMONIC="" and fund your wallet in order to deploy!

## BasedOFT.sol - an omnichain ERC20

> WARNING: **You must perform the setTrustedRemote() (step 2).**

1. Deploy two contracts:  ```rinkeby``` is the `base` chain
```angular2html
 npx hardhat --network rinkeby deploy --tags BasedOFT
 npx hardhat --network fuji deploy --tags BasedOFT
```
2. Set the "trusted remotes" (ie: your contracts) so each of them can receive messages from one another, and `only` one another.
```angular2html
npx hardhat --network rinkeby oftSetTrustedRemote --target-network fuji
npx hardhat --network fuji oftSetTrustedRemote --target-network rinkeby
```
3. Send tokens from rinkeby to fuji
```angular2html
npx hardhat --network rinkeby oftSendTokens --target-network fuji --qty 250
```


# OmnichainNonFungibleToken (ONFT)

This ONFT contract allows minting of `nftId`s on separate chains. To ensure two chains can not mint the same `nfId` each contract on each chain is only allowed to mint`nftIds` in certain ranges.
Check `constants/onftArgs.json` for the specific test configuration used in this demo.
## UniversalONFT.sol 

> WARNING: **You must perform the setTrustedRemote() (step 2).**

1. Deploy two contracts:
```angular2html
 npx hardhat --network bsc-testnet deploy --tags UniversalONFT
 npx hardhat --network fuji deploy --tags UniversalONFT
```
2. Set the "trusted remotes", so each contract can send & receive messages from one another, and `only` one another.
```angular2html
 npx hardhat --network bsc-testnet onftSetTrustedRemote --target-network fuji
 npx hardhat --network fuji onftSetTrustedRemote --target-network bsc-testnet
```
3. Mint an NFT on each chain!
```angular2html
 npx hardhat --network bsc-testnet onftMint
 npx hardhat --network fuji onftMint
```
4. [Optional] Show the token owner(s)
```angular2html
 npx hardhat --network bsc-testnet onftOwnerOf --token-id 1
 npx hardhat --network fuji onftOwnerOf --token-id 51
```
5. Send ONFT across chains
```angular2html
npx hardhat --network bsc-testnet onftSend --target-network fuji --token-id 1
```
6. Verify your token no longer exists on the source chain & wait for it to reach the destination side.
```angular2html
 npx hardhat --network bsc-testnet  onftOwnerOf --token-id 1
 npx hardhat --network fuji  onftOwnerOf --token-id 1
```


# OmniCounter.sol

OmniCounter is a simple contract with a counter. You can only *remotely* increment the counter!

1. Deploy both OmniCounters:

```
npx hardhat --network bsc-testnet deploy --tags OmniCounter
npx hardhat --network fuji deploy --tags OmniCounter
````

2. Set the remote addresses, so each contract can receive messages
```angular2html
npx hardhat --network bsc-testnet ocSetTrustedRemote --target-network fuji
npx hardhat --network fuji ocSetTrustedSource --target-network bsc-testnet
```
3. Send a cross chain message from `mumbai` to `fuji` !
```angular2html
npx hardhat --network bsc-testnet ocIncrementCounter --target-network fuji
```

Optionally use this command in a separate terminal to watch the counter increment in real-time.
```
npx hardhat --network fuji omniCounterPoll    
```

# Testing Multiple Cross Chain Messages

1. Deploy both OmniCounters:

```
npx hardhat --network bsc-testnet deploy --tags OmniCounter
npx hardhat --network fuji deploy --tags OmniCounter
npx hardhat --network mumbai deploy --tags OmniCounter
npx hardhat --network fantom-testnet deploy --tags OmniCounter
````

2. Set the remote addresses, so each contract can receive messages
```angular2html
npx hardhat --network bsc-testnet ocSetTrustedRemote --target-network fuji
npx hardhat --network fuji ocSetTrustedRemote --target-network bsc-testnet

npx hardhat --network bsc-testnet ocSetTrustedRemote --target-network mumbai
npx hardhat --network mumbai ocSetTrustedRemote --target-network bsc-testnet

npx hardhat --network bsc-testnet ocSetTrustedRemote --target-network fantom-testnet
npx hardhat --network fantom-testnet ocSetTrustedRemote --target-network bsc-testnet
```
3. Send a cross chain message from `mumbai` to `fuji` !
```angular2html
npx hardhat --network bsc-testnet omniCounterIncrementMultiCounter --target-networks fuji,mumbai,fantom-testnet
```

Optionally use this command in a separate terminal to watch the counter increment in real-time.
```
npx hardhat --network fuji omniCounterPoll
npx hardhat --network mumbai omniCounterPoll
npx hardhat --network fantom-testnet omniCounterPoll
```
# Getting and Setting the Oracle

### Read the currently set Oracle
```npx hardhat --network bsc-testnet omniCounterGetOracle --target-network fantom-testnet```

### Set a custom Oracle for the deployed OmniCounter
```npx hardhat --network bsc-testnet omniCounterSetOracle --target-network fantom-testnet --oracle 0x000000000000000000000000000000000000dEaD```
#
### See some examples in `/contracts`  🙌

Many of the example contracts make use of LayerZeroEndpointMock.sol which is a nice way to test LayerZero locally!

### For further reading, and a list of endpoint ids and deployed LayerZero contract addresses please take a look at the Gitbook here: https://layerzero.gitbook.io/

## Most recently tested with node version `16.13.1` 

