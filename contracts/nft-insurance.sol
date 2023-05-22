pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

// NFTInsurance contract, which is a contract for managing the insurance for NFTs.
contract NFTInsurance is Ownable {
    mapping(address => uint) public buyersPool;
    mapping(address => uint) public sellersPool;
    address[] public buyers;
    address[] public sellers;
    uint public compensationAmount;
    uint public insuranceAmount;
    uint public currentPrice;
    uint public compensationPrice;
    uint public distributionTime;
    bool public isCompensatable;
    uint public zkSyncBlockTime = 1 seconds;

    // Allows buyers to deposit funds into the buyers' pool.
    function depositToBuyersPool() public payable {
        buyersPool[msg.sender] += msg.value;
        insuranceAmount += msg.value;
        buyers.push(msg.sender);
    }

    // Allows sellers to deposit funds into the sellers' pool.
    function depositToSellersPool() public payable {
        sellersPool[msg.sender] += msg.value;
        compensationAmount += msg.value;
        sellers.push(msg.sender);
    }

    // Allows the contract owner to set the current and compensation prices.
    function setPrices(
        uint _currentPrice,
        uint _compensationPrice
    ) external onlyOwner {
        currentPrice = _currentPrice;
        compensationPrice = _compensationPrice;
    }

    // Allows the contract owner to set the due time for the insurance distribution.
    function setDueTime(uint _dueTime) external onlyOwner {
        distributionTime = _dueTime;
    }

    // Allows the contract owner to trigger the compensation if the current price is less than the compensation price.
    function setCompensatable() external onlyOwner {
        require(
            currentPrice < compensationPrice,
            "Current price is not less than compensation price."
        );
        isCompensatable = true;
    }

    // Allows buyers to claim their compensation when the compensation condition is triggered.
    function claimCompensation() external {
        require(
            isCompensatable == true,
            "Compensation has not been triggered."
        );
        uint compensationShare = (buyersPool[msg.sender] / insuranceAmount) *
            compensationAmount;
        uint buyerShare = compensationShare + buyersPool[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: buyerShare}("");
        require(success, "Transfer failed.");
        insuranceAmount = insuranceAmount - buyersPool[msg.sender];
        compensationAmount = compensationAmount - compensationShare;
    }

    // Allows sellers to claim the insurance amount after the due time.
    function claimInsuranceAmount() external {
        // todo add due time require
        // require(
        //     block.timestamp >= distributionTime * zkSyncBlockTime,
        //     "Due time has not been reached."
        // );
        uint insuranceShare = (sellersPool[msg.sender] / compensationAmount) *
            insuranceAmount;
        uint sellerShare = insuranceShare + sellersPool[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: sellerShare}("");
        require(success, "Transfer failed.");
        insuranceAmount = insuranceAmount - insuranceShare;
        compensationAmount = compensationAmount - sellersPool[msg.sender];
    }

    // Returns all addresses in the buyers' pool.
    function getAllBuyers() public view returns (address[] memory) {
        return buyers;
    }

    // Returns all addresses in the sellers' pool.
    function getAllSellers() public view returns (address[] memory) {
        return sellers;
    }

    // Allows the contract owner to withdraw all the funds from the contract.
    function withdrawFees() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}

    fallback() external payable {}
}
