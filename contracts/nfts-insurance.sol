pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTsInsurance is Ownable {
    struct Insurance {
        mapping(address => uint) buyersPool;
        mapping(address => uint) sellersPool;
        address[] buyers;
        address[] sellers;
        uint compensationAmount;
        uint insuranceAmount;
        uint currentPrice;
        uint compensationPrice;
        uint expiredTime;
        bool isCompensatable;
        // todo add bool expired
        // todo add unit epoch
    }

    mapping(address => Insurance) public insurances;

    address[] public insuracneNftAddrs;
    uint public zkSyncBlockTime = 1 seconds;

    function depositToBuyersPool(address nftAddress) public payable {
        insurances[nftAddress].buyersPool[msg.sender] += msg.value;
        insurances[nftAddress].insuranceAmount += msg.value;
        insurances[nftAddress].buyers.push(msg.sender);
    }

    function depositToSellersPool(address nftAddress) public payable {
        insurances[nftAddress].sellersPool[msg.sender] += msg.value;
        insurances[nftAddress].compensationAmount += msg.value;
        insurances[nftAddress].sellers.push(msg.sender);
    }

    function addInsurance(address nftAddress) public onlyOwner {
        // Check that the insurance does not already exist
        require(
            insurances[nftAddress].expiredTime == 0,
            "Insurance already exists for this NFT."
        );
        insuracneNftAddrs.push(nftAddress);
        // No need to explicitly set default values, they are automatically set
        // insurances[nftAddress].isCompensatable = false;
        // insurances[nftAddress].buyers = [];
        // insurances[nftAddress].sellers = [];
    }

    function setPrices(
        address nftAddress,
        uint _currentPrice,
        uint _compensationPrice
    ) external onlyOwner {
        insurances[nftAddress].currentPrice = _currentPrice;
        insurances[nftAddress].compensationPrice = _compensationPrice;
        if (_currentPrice < _compensationPrice) {
            insurances[nftAddress].isCompensatable = true;
        }
    }

    function setExpiredTime(
        address nftAddress,
        uint _expiredTime
    ) external onlyOwner {
        insurances[nftAddress].expiredTime = _expiredTime;
    }

    function setCompensatable(address nftAddress) external onlyOwner {
        require(
            insurances[nftAddress].currentPrice <
                insurances[nftAddress].compensationPrice,
            "Current price is not less than compensation price."
        );
        insurances[nftAddress].isCompensatable = true;
    }

    function claimCompensation(address nftAddress) external {
        require(
            insurances[nftAddress].isCompensatable == true,
            "Compensation has not been triggered."
        );
        uint compensationShare = (insurances[nftAddress].buyersPool[
            msg.sender
        ] / insurances[nftAddress].insuranceAmount) *
            insurances[nftAddress].compensationAmount;
        uint buyerShare = compensationShare +
            insurances[nftAddress].buyersPool[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: buyerShare}("");
        require(success, "Transfer failed.");
        insurances[nftAddress].insuranceAmount =
            insurances[nftAddress].insuranceAmount -
            insurances[nftAddress].buyersPool[msg.sender];
        insurances[nftAddress].compensationAmount =
            insurances[nftAddress].compensationAmount -
            compensationShare;
    }

    function claimInsuranceAmount(address nftAddress) external {
        // todo require expried time is true
        uint insuranceShare = (insurances[nftAddress].sellersPool[msg.sender] /
            insurances[nftAddress].compensationAmount) *
            insurances[nftAddress].insuranceAmount;
        uint sellerShare = insuranceShare +
            insurances[nftAddress].sellersPool[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: sellerShare}("");
        require(success, "Transfer failed.");
        insurances[nftAddress].insuranceAmount =
            insurances[nftAddress].insuranceAmount -
            insuranceShare;
        insurances[nftAddress].compensationAmount =
            insurances[nftAddress].compensationAmount -
            insurances[nftAddress].sellersPool[msg.sender];
    }

    function getAllBuyers(
        address nftAddress
    ) public view returns (address[] memory) {
        return insurances[nftAddress].buyers;
    }

    function getAllSellers(
        address nftAddress
    ) public view returns (address[] memory) {
        return insurances[nftAddress].sellers;
    }

    function withdrawFees() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}

    fallback() external payable {}
}
