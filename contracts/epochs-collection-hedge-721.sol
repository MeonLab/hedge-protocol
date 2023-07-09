pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./insurance-structure.sol";
import "./insurance-functions.sol";

contract EpochCollectionHedge721 is
    Ownable,
    ReentrancyGuard,
    ERC721("NFTHedge", "NFTH")
{
    using Math for uint256;

    mapping(uint256 => Insurance) public insurances;
    uint256 private tokenId = 0;
    uint256 private epoch = 0;
    uint256 private dueTime = 30;

    function deposit(
        uint256 _amount,
        bool isBuyer,
        uint256 _epoch
    ) external payable {
        require(_epoch <= epoch, "Not valid epoch");
        require(insurances[_epoch].locked == false, "Locked");
        _safeMint(msg.sender, tokenId);
        InsuranceFunctions.deposit(
            tokenId,
            _amount,
            isBuyer,
            insurances[_epoch]
        );
        tokenId++;
    }

    function setCurrentPrices(
        uint256 _currentPrice,
        uint256 _epoch
    ) external onlyOwner {
        insurances[_epoch].currentPrice = _currentPrice;
    }

    function setLiquidationPrices(
        uint256 _compensationPrice,
        uint256 _epoch
    ) external onlyOwner {
        insurances[_epoch].liquidationPrice = _compensationPrice;
    }

    function setDueTime(uint256 _dueTime, uint256 _epoch) external onlyOwner {
        dueTime = _dueTime;
    }

    function lockPool(uint256 _epoch) external onlyOwner {
        insurances[_epoch].lockedSellersFundAmount = insurances[_epoch]
            .sellersFundAmount;
        insurances[_epoch].lockedBuyersFundAmount = insurances[_epoch]
            .buyersFundAmount;
        insurances[_epoch].locked = true;
    }

    function setCompensatable(uint256 _epoch) external onlyOwner {
        require(
            insurances[_epoch].currentPrice <
                insurances[_epoch].liquidationPrice,
            "Current price is not less than compensation price."
        );

        require(
            insurances[_epoch].expirationDate < block.timestamp,
            "This epoch insurance is over."
        );

        insurances[_epoch].isCompensatable = true;
    }

    function claimCompensation(uint256 _tokenId, uint256 _epoch) external {
        require(_epoch <= epoch, "Not valid epoch");

        require(
            insurances[_epoch].isCompensatable == true,
            "Compensation has not been triggered."
        );
        require(
            ownerOf(_tokenId) == msg.sender,
            "Caller is not the owner of this token."
        );

        uint256 buyerTotallyEarn = InsuranceFunctions.claimCompensation(
            _tokenId,
            insurances[_epoch]
        );
        (bool success, ) = payable(msg.sender).call{value: buyerTotallyEarn}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function claimInsurance(uint256 _tokenId, uint256 _epoch) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Caller is not the owner of this token."
        );

        require(_epoch <= epoch, "Not valid epoch");

        require(
            insurances[_epoch].expirationDate < block.timestamp,
            "Due time is not reached."
        );

        uint256 sellerTotallyEarn = InsuranceFunctions.claimInsurance(
            _tokenId,
            insurances[_epoch]
        );

        (bool success, ) = payable(msg.sender).call{value: sellerTotallyEarn}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function getReturn(
        uint _epoch,
        uint _tokenId,
        bool isInsurance
    ) public view returns (uint256) {
        if (isInsurance) {
            uint256 buyerOwnPart = insurances[_epoch].buyersPool[_tokenId];
            uint256 buyerTotallyEarn = buyerOwnPart.mulDiv(
                insurances[_epoch].lockedSellersFundAmount,
                insurances[_epoch].lockedBuyersFundAmount
            );
            return buyerTotallyEarn;
        } else {
            uint256 sellerOwnPart = insurances[_epoch].sellersPool[_tokenId];
            uint256 sellerEarn = sellerOwnPart.mulDiv(
                insurances[_epoch].lockedBuyersFundAmount,
                insurances[_epoch].lockedSellersFundAmount
            );

            // uint256 sellerTotallyEarn = sellerEarn;
            return sellerEarn;
        }
    }

    function getAllBuyers(
        uint256 _epoch
    ) public view returns (uint256[] memory) {
        require(_epoch <= epoch, "Not valid epoch");

        return insurances[_epoch].buyers;
    }

    function getAllSellers(
        uint256 _epoch
    ) public view returns (uint256[] memory) {
        require(_epoch <= epoch, "Not valid epoch");

        return insurances[_epoch].sellers;
    }

    // todo: add contract fee
    function withdrawFees() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    // create new insurance
    function startNewEpoch() external onlyOwner {
        uint256 new_epoch = epoch + 1;
        epoch = new_epoch;
        insurances[new_epoch].expirationDate = block.timestamp + dueTime;
    }

    function setExpirationDate(uint256 _expirationDate) external onlyOwner {
        require(_expirationDate > block.timestamp, "Not valid expiration date");
        insurances[epoch].expirationDate = _expirationDate;
    }

    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function getSellerPool(
        uint256 _tokenId,
        uint256 _epoch
    ) public view returns (uint256) {
        return insurances[_epoch].sellersPool[_tokenId];
    }

    function getBuyerPool(
        uint256 _tokenId,
        uint256 _epoch
    ) public view returns (uint256) {
        return insurances[_epoch].buyersPool[_tokenId];
    }

    receive() external payable {}

    fallback() external payable {}
}
