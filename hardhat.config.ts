require('@nomicfoundation/hardhat-toolbox')
const secrets = require('./secrets.json')

module.exports = {
    solidity: '0.8.20',
    networks: {
        hardhat: {
            chainId: 1337,
        },
        arbitrumGoerli: {
            url: 'https://goerli-rollup.arbitrum.io/rpc',
            chainId: 421613,
            accounts: [secrets.meon2PrivateKey],
        },
        arbitrumOne: {
            url: 'https://arb1.arbitrum.io/rpc',
            //accounts: [ARBITRUM_MAINNET_TEMPORARY_PRIVATE_KEY]
        },
    },
    etherscan: {
        apiKey: secrets.arbscanApiKey,
    },
}
