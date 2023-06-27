import '@matterlabs/hardhat-zksync-deploy'
import '@matterlabs/hardhat-zksync-solc'
import '@matterlabs/hardhat-zksync-verify'

import secrets from './secrets.json'

module.exports = {
    zksolc: {
        version: '1.3.8',
        compilerSource: 'binary',
        settings: {},
    },
    defaultNetwork: 'zkSyncTestnet',

    networks: {
        zkSyncTestnet: {
            url: 'https://zksync2-testnet.zksync.dev',
            ethNetwork: `https://goerli.infura.io/v3/${secrets.infuraApiKey}`, // Can also be the RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
            zksync: true,
            verifyURL:
                'https://zksync2-testnet-explorer.zksync.dev/contract_verification',
        },
        zkSyncLocalnet: {
            url: 'http://localhost:3050/',
            ethNetwork: `http://localhost:8545/`, // Can also be the RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
            zksync: true,
        },
        zkSyncMainnet: {
            url: 'https://mainnet.era.zksync.io',
            ethNetwork: `https://mainnet.infura.io/v3/${secrets.infuraApiKey}`, // Can also be the RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
            zksync: true,
            verifyURL:
                'https://zksync2-mainnet-explorer.zksync.io/contract_verification',
        },
    },
    solidity: {
        version: '0.8.19',
    },
}