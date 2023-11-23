const hre = require('hardhat')

async function main() {
    const vault = await hre.ethers.deployContract('HedgeVault')
    await vault.waitForDeployment()
    console.log(`Hedge Vault deployed to ${vault.target}`)
}

main().catch((error) => {
    console.error(error)
    process.exit(1)
})
