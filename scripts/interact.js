// import { Wallet } from 'zksync-web3'
// import secrets from '../secrets.json'

// async function main() {
//     const wallet = new Wallet(secrets.privateKey)
//     const contract = await ethers.getContractFactory('TokenDistributor')
//     const onChainContract = await contract.attach(
//         '0xA4202309B49a0BAC66d4e82F1888ef5493a5Ba50'
//     )

//     // await onChainContract.mint(1)
//     await onChainContract.safeTransferFrom(
//         '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
//         '0x71C95911E9a5D330f4D621842EC243EE1343292e',
//         0
//     )
//     // await onChainContract.setBaseURI("https://cloudflare-ipfs.com/ipfs/QmdGgK2w7Qiq3mpkaKdUJpa8hdWM8BYCPZAhx81tPHToYj/")
//     // await onChainContract.tokenURI(0)
//     //     .then((res) => {
//     //         console.log(res)
//     //     }).catch((e) => {
//     //         console.log(e);
//     //     })
//     console.log('done')
// }

// main()

import { ethers } from 'ethers'
import { Wallet, Contract, Provider } from 'zksync-web3'
import secrets from '../secrets.json'
const CONTRACT_ADDRESS = '0xA4202309B49a0BAC66d4e82F1888ef5493a5Ba50'
const CONTRACT_ABI = require('./abi/abi.json')
function getSignerAndContract() {
    const provider = new Provider('https://zksync2-testnet.zksync.dev')
    // const provider = new Provider('http://localhost:3050/');
    const signer = new Wallet(secrets.privateKey, provider)
    const contract = new Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer)
    return [signer, contract]
}
async function contractCall() {
    const init = getSignerAndContract()
    const signer = init[0]
    const contract = init[1]
    const x = await contract.distributeTokenEvenly(proof)
    console.log(x)
}
contractCall()
// main()
