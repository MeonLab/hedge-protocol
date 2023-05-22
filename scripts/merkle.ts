import { ethers } from 'ethers'
import { Wallet, Contract, Provider } from "zksync-web3";
import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'
import secrets from '../secrets.json';

const CONTRACT_ADDRESS = "0xFd4F026856ca8a1fBc5DD9e14DC2343b4A3c0FE3"
const CONTRACT_ABI = require("./abi/abi.json");

function getSignerAndContract() {
    // const provider = new Provider('https://zksync2-testnet.zksync.dev');
    const provider = new Provider('http://localhost:3050/');

    const signer = new Wallet(secrets.privateKey, provider);
    const contract = new Contract(
        CONTRACT_ADDRESS,
        CONTRACT_ABI,
        signer
    );
    return [signer, contract]
};

function getWlList() {
    let wl = require('./wl.json')
    for (let i = 0; i < wl.length; ++i) {
        wl[i] = wl[i].toLowerCase()
        if (!ethers.utils.isAddress(wl[i])) {
            console.log(wl[i], 'is wrong address.')
            process.exit()
        }
    }
    wl = new Set(wl)
    wl = Array.from(wl)
    console.log('all address is correct !')
    return wl
}

async function main() {
    const whitelistAddresses = getWlList()

    const leafNodes = whitelistAddresses.map((addr) => keccak256(addr))
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
    console.log('Whitelist Merkle Tree:\n', merkleTree.toString())

    // const rootHash = merkleTree.getRoot();
    // console.log(rootHash)
    const buf2hex = x => '0x' + x.toString('hex');
    const address =  keccak256("0xA181c54996e17a67f82f2F92F3B6A3BD7405b373".toLowerCase())
    const proof = merkleTree.getHexProof(address);
    const root = merkleTree.getHexRoot();
    console.log(root)
    console.log(proof)

    console.log(merkleTree.verify(proof, address, root));

}

async function contractCall(){
    const whitelistAddresses = getWlList()
    const leafNodes = whitelistAddresses.map((addr) => keccak256(addr))
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
    console.log('Whitelist Merkle Tree:\n', merkleTree.toString())

    const init = getSignerAndContract()
    const signer = init[0]
    const contract = init[1]

    const address = signer.address.toLowerCase()
    const leaf = keccak256(address)
    const proof = merkleTree.getHexProof(leaf);
    const root = merkleTree.getHexRoot();
    console.log(root)
    console.log(proof)

    const x = await contract.isWhiteList(proof)
    console.log(x)

}

// contractCall()
main()
