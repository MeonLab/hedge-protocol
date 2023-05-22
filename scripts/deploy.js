async function main() {
    // We get the contract to deploy
    let accounts_list = await ethers.getSigners();
    let account = accounts_list[1]
    const contract = await ethers.getContractFactory('FomoNFT');
    console.log('Deploying contract...');
    const deploy_contract = await contract.connect(account).deploy();
    await deploy_contract.deployed();
    console.log('contract deployed to:', deploy_contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });