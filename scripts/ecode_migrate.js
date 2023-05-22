const fs = require('fs');
const ethers = require("ethers")
private_key = JSON.parse(fs.readFileSync('./secret.json'))["acc0_private_key"];

var goerli_url = 'https://goerli.infura.io/v3/995b2e86842243faac38ee07cae4d6ca';
var GOERLI_PROVIDER = new ethers.providers.JsonRpcProvider(goerli_url);

const ecode_migrate = async () => {

    // accounts = await ethers.provider.listAccounts()
    const signer = new ethers.Wallet(private_key, GOERLI_PROVIDER);

    const ecode_address = "0x3626dbED81CD2bdc8ba70adB3b8fB370ea1d76cf";
    let ecode_abi = fs.readFileSync('./scripts/ecode.json');
    ecode_abi = JSON.parse(ecode_abi);
    const ecode_contract = new ethers.Contract(ecode_address, ecode_abi, signer);


    const tx = await ecode_contract.connect(signer).migrate([1], [1]);
    const receipt = await tx.wait();
    console.log(receipt.transactionHash);

    // const estimatedGasLimit = await ecode_contract.estimateGas.migrate([1], [1]);
    // const migrateTxUnsigned = await ecode_contract.populateTransaction.migrate([1], [1]);
    // migrateTxUnsigned.chainId = 5; // chainId 1 for Ethereum mainnet
    // migrateTxUnsigned.gasLimit = 100000;
    // migrateTxUnsigned.gasPrice = await GOERLI_PROVIDER.getGasPrice();
    // migrateTxUnsigned.nonce = await GOERLI_PROVIDER.getTransactionCount("0x331563fE06fb50D423379B5ec1EdAA3d9787513a");

    // const migrateTxSigned = await signer.signTransaction(migrateTxUnsigned)
    // const submittedTx = await GOERLI_PROVIDER.sendTransaction(migrateTxSigned);
    // const approveReceipt = await submittedTx.wait();
    // if (approveReceipt.status === 0) {
    //     console.log("==========================")
    //     throw new Error("Approve transaction failed");
    // }

}




ecode_migrate()