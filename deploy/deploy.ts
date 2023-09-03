import { Wallet } from 'zksync-web3'
import * as ethers from 'ethers'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { Deployer } from '@matterlabs/hardhat-zksync-deploy'

import secrets from '../secrets.json'

const parameters = ['0xfb3210f3C01671C24f4ecE8669A8b5d802796b55']
// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
    const contractName = 'NftHedgeProtocol'
    console.log(`Running deploy script for the ${contractName} contract`)

    // Initialize the wallet.
    const wallet = new Wallet(secrets.privateKey)

    // Create deployer object and load the artifact of the contract you want to deploy.
    const deployer = new Deployer(hre, wallet)
    const artifact = await deployer.loadArtifact(contractName)

    // Estimate contract deployment fee

    const deploymentFee = await deployer.estimateDeployFee(artifact, parameters)

    // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
    // `greeting` is an argument for contract constructor.
    const parsedFee = ethers.utils.formatEther(deploymentFee.toString())
    console.log(`The deployment is estimated to cost ${parsedFee} ETH`)

    const contract = await deployer.deploy(artifact, parameters)

    //obtain the Constructor Arguments
    // console.log('constructor args:' + contract.interface.encodeDeploy([]))

    // Show the contract info.
    const contractAddress = contract.address
    console.log(`${artifact.contractName} was deployed to ${contractAddress}`)
}
