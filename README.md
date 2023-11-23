# Setup

1. yarn install
2. setup secrets.json

```json
{
    "infuraApiKey": "your infura api key",
    "etherscanAPiKey": "your infura etherscan key",
    "privateKey": "your wallet private key"
}
```

# How to deploy on Arbitrum ?

1.  ```bash
    yarn hardhat compile
    ```
2.  ```bash
    yarn hardhat run ./scripts/deployMETH.js --network arbitrumGoerli
    ```
3.  ```bash
    yarn hardhat run ./scripts/deployVault.js --network arbitrumGoerli
    ```
4.  -   need to modify the parameters if there are arguments for contract to init
    -   change the name of contract in script
    ```nodejs
    const protocol = await hre.ethers.deployContract(nameOfContract, [
        vaultContract,
        hedgeTarget,
    ])
    ```
    ```bash
    yarn hardhat run ./scripts/deployHedgeProtocol.js --network <networks(in hardhat.config.js)>
    ```
5.  default run zkSyncTestnet
    -   need to modify the parameters if there are arguments for contract to init
    ```bash
    yarn hardhat verify --network <networks(in hardhat.config.js)> <contract address> ""
    ```
