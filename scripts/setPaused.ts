import { Wallet, utils, Contract, Web3Provider, Provider } from "zksync-web3";
// import * as ethers from "ethers";
// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

import secrets from '../secrets.json';

const CONTRACT_ADDRESS = "0xC5EF40b2E1d843Ae77bE329Cd6d9Dd12369Bb25b"
const CONTRACT_ABI = require("./abi/abi.json");

function initializeProviderAndSigner() {
    const provider = new Provider('https://zksync2-testnet.zksync.dev');

    const signer = new Wallet(secrets.privateKey, provider);
    const contract = new Contract(
        CONTRACT_ADDRESS,
        CONTRACT_ABI,
        signer
    );
    return [provider,signer,contract]
};


async function main(){
    const inits = initializeProviderAndSigner()
    const provider = inits[0]
    const signer = inits[1]
    const contract = inits[2]

    // console.log(await contract.paused())
    const x = await contract.setPaused(false)
    console.log(x)
    console.log(await x.wait())

}
main()



