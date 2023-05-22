import * as zksync from 'zksync-web3'
import * as ethers from 'ethers'
import secrets from '../secrets.json'
// const IERC20 = require('@openzeppelin/contracts/token/ERC20/IERC20.sol')

const CONTRACT_ABI = require('./abi/abi.json')

async function getSignerAndContract() {
    // Currently, only one environment is supported.
    const zkSyncProvider = new zksync.Provider('https://testnet.era.zksync.dev')
    const ethProvider = ethers.getDefaultProvider('goerli')

    // Derive zksync.Wallet from ethereum private key.
    // zkSync's wallets support all of the methods of ethers' wallets.
    // Also, both providers are optional and can be connected to later via `connect` and `connectToL1`.
    const zkSyncWallet = new zksync.Wallet(
        secrets.privateKey,
        zkSyncProvider,
        ethProvider
    )

    const deposit = await zkSyncWallet.deposit({
        token: zksync.utils.ETH_ADDRESS,
        amount: ethers.utils.parseEther('1.0'),
    })

    // Retrieving the ETH balance of an account in the last finalized zkSync block.
    const finalizedEthBalance = await zkSyncWallet.getBalance(
        zksync.utils.ETH_ADDRESS,
        'finalized'
    )

    console.log(
        'zksync eth finalized:',
        ethers.utils.formatEther(finalizedEthBalance)
    )
}
getSignerAndContract()
// main()
