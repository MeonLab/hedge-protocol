pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// NFTInsurance contract, which is a contract for managing the insurance for NFTs.
contract NFTInsurance is Ownable ERC721("NFTHedge", "NFTH")  {
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
    uint private tokenId = 0;


    // Allows buyers to deposit funds into the buyers' pool.
    function depositToBuyersPool() public payable {
        _safeMint(msg.sender, tokenId);
        buyersPool[tokenId] = msg.value;
        insuranceAmount += msg.value;
        buyers.push(tokenId);
        tokenId++;
    }

    // Allows sellers to deposit funds into the sellers' pool.
    function depositToSellersPool() public payable {
        _safeMint(msg.sender, tokenId);
        sellersPool[tokenId] = msg.value;
        compensationAmount += msg.value;
        sellers.push(tokenId);
        tokenId++;
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
    function claimCompensation(uint _tokenId) external {
        require(
            isCompensatable == true,
            "Compensation has not been triggered."
        );
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this token.");
        uint compensationShare = (buyersPool[_tokenId] / insuranceAmount) * compensationAmount;
        uint buyerShare = compensationShare + buyersPool[_tokenId];
        (bool success, ) = payable(msg.sender).call{value: buyerShare}("");
        require(success, "Transfer failed.");
        insuranceAmount = insuranceAmount - buyersPool[_tokenId];
        compensationAmount = compensationAmount - compensationShare;
    }

    // Allows sellers to claim the insurance amount after the due time.
    function claimInsuranceAmount(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this token.");
        uint insuranceShare = (sellersPool[_tokenId] / compensationAmount) * insuranceAmount;
        uint sellerShare = insuranceShare + sellersPool[_tokenId];
        (bool success, ) = payable(msg.sender).call{value: sellerShare}("");
        require(success, "Transfer failed.");
        insuranceAmount = insuranceAmount - insuranceShare;
        compensationAmount = compensationAmount - sellersPool[_tokenId];
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
