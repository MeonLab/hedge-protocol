const hre = require('hardhat')

async function main() {
    const protocol = await hre.ethers.deployContract('METH')
    await protocol.waitForDeployment()
    console.log(`MeonETH deployed to ${protocol.target}`)
}

main().catch((error) => {
    console.error(error)
    process.exit(1)
})
