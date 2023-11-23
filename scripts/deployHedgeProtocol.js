const hre = require('hardhat')

async function main() {
    const protocol = await hre.ethers.deployContract('NftHedgeProtocol', [
        '0xE7c4F5B1f738A0fED3360d751E32b2fbf9D489C5',
        'moonbirds',
    ])
    await protocol.waitForDeployment()
    console.log(`Hedge protocol deployed to ${protocol.target}`)
}

main().catch((error) => {
    console.error(error)
    process.exit(1)
})
