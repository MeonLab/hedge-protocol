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

# How to deploy on zkSync Era ?

1.  ```bash
    yarn hardhat compile
    ```
    copy abi from artifacts/contracts/contractName.json to scripts/abi/abi.json
2.  The actual running file is ./deploy/deploy.ts
    -   need to modify the parameters if there are arguments for contract to init
    -   change the name of contract in script
    ```nodejs
    const artifact = await deployer.loadArtifact('nameOfContract')
    ```
    default run testNet
    ```bash
    yarn hardhat deploy-zksync --network <networks(in hardhat.config.ts)>
    ```
3.  default run zkSyncTestnet

    -   need to modify the parameters if there are arguments for contract to init

    ```bash
    yarn hardhat verify --network zkSyncTestnet <contract address> ""
    ```
