pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// NFTInsurance contract, which is a contract for managing the insurance for NFTs.
contract CollectionHedge721 is Ownable, ERC721("NFTHedge", "NFTH") {
    mapping(uint256 => uint) public buyersPool;
    mapping(uint256 => uint) public sellersPool;
    uint[] public buyers;
    uint[] public sellers;
    uint public compensationAmount;
    uint public insuranceAmount;
    uint public lockedCompensationAmount;
    uint public lockedInsuranceAmount;
    uint public currentPrice;
    uint public compensationPrice;
    uint public dueTime;
    bool public isCompensatable;
    uint256 private tokenId = 0;

    // Deposit function shared by buyers and sellers
    function deposit(
        uint _amount,
        uint[] storage _pool,
        bool isBuyer
    ) internal {
        // todo: check due time
        _safeMint(msg.sender, tokenId);
        if (isBuyer) {
            buyersPool[tokenId] = _amount;
            insuranceAmount += _amount;
        } else {
            sellersPool[tokenId] = _amount;
            compensationAmount += _amount;
        }
        _pool.push(tokenId);
        tokenId++;
    }

    // Allows buyers to deposit funds into the buyers' pool.
    function depositToBuyersPool() public payable {
        deposit(msg.value, buyers, true);
    }

    // Allows sellers to deposit funds into the sellers' pool.
    function depositToSellersPool() public payable {
        deposit(msg.value, sellers, false);
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
        dueTime = _dueTime;
        lockedCompensationAmount = compensationAmount;
        lockedInsuranceAmount = insuranceAmount;
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
        require(
            ownerOf(_tokenId) == msg.sender,
            "Caller is not the owner of this token."
        );
        uint compensationShare = (buyersPool[_tokenId] /
            lockedInsuranceAmount) * lockedCompensationAmount;
        uint buyerShare = compensationShare + buyersPool[_tokenId];
        (bool success, ) = payable(msg.sender).call{value: buyerShare}("");
        require(success, "Transfer failed.");
        buyersPool[_tokenId] = 0;
        insuranceAmount = insuranceAmount - buyersPool[_tokenId];
        compensationAmount = compensationAmount - compensationShare;
    }

    // Allows sellers to claim the insurance amount after the due time.
    function claimInsurance(uint _tokenId) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Caller is not the owner of this token."
        );
        // todo: check due time
        uint insuranceShare = (sellersPool[_tokenId] /
            lockedCompensationAmount) * lockedInsuranceAmount;
        uint sellerShare = insuranceShare + sellersPool[_tokenId];
        (bool success, ) = payable(msg.sender).call{value: sellerShare}("");
        require(success, "Transfer failed.");
        sellersPool[_tokenId] = 0;
        insuranceAmount = insuranceAmount - insuranceShare;
        compensationAmount = compensationAmount - sellersPool[_tokenId];
    }

    // Returns all addresses in the buyers' pool.
    function getAllBuyers() public view returns (uint[] memory) {
        return buyers;
    }

    // Returns all addresses in the sellers' pool.
    function getAllSellers() public view returns (uint[] memory) {
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
