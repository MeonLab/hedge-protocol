pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./insurance-structure.sol";
import "./insurance-functions.sol";
import "./insurance-error.sol";

// TODO: record the price of all deposits
contract EpochCollectionHedge721 is
    Ownable,
    ReentrancyGuard,
    ERC721("NFTHedge", "NFTH")
{
    using Math for uint256;

    mapping(uint256 => Insurance) public insurances;
    uint256 private tokenId = 0;
    uint256 private epoch = 0;
    // TODO: duetime should be duration done
    uint256 private duration = 30;

    // TODO should be if (_epoch == epoch) revert InvalidEpoch(_epoch, epoch); done
    function deposit(bool isBuyer, uint256 _epoch) external payable {
        if (_epoch == epoch) revert InvalidEpoch(_epoch, epoch);
        if (insurances[_epoch].locked) revert PoolLocked();

        _safeMint(msg.sender, tokenId);
        InsuranceFunctions.deposit(
            tokenId,
            msg.value,
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

    // TODO: remove _epoch done
    function setDueTime(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function lockPool(uint256 _epoch) external onlyOwner {
        insurances[_epoch].lockedSellersFundAmount = insurances[_epoch]
            .sellersFundAmount;
        insurances[_epoch].lockedBuyersFundAmount = insurances[_epoch]
            .buyersFundAmount;
        insurances[_epoch].locked = true;
    }

    // TODO: currentPrice > liquidationPrice done
    function setCompensatable(uint256 _epoch) external onlyOwner {
        if (
            insurances[_epoch].currentPrice >
            insurances[_epoch].liquidationPrice
        )
            revert CurrentPriceNotLessThanCompensationPrice(
                insurances[_epoch].currentPrice,
                insurances[_epoch].liquidationPrice
            );

        if (insurances[_epoch].expirationDate >= block.timestamp)
            revert InsuranceOver(
                insurances[_epoch].expirationDate,
                block.timestamp
            );

        insurances[_epoch].isCompensatable = true;
    }

    function claimCompensation(uint256 _tokenId, uint256 _epoch) external {
        if (_epoch > epoch) revert InvalidEpoch(_epoch, epoch);

        if (!insurances[_epoch].isCompensatable)
            revert CompensationNotTriggered();

        if (ownerOf(_tokenId) != msg.sender)
            revert NotTokenOwner(msg.sender, ownerOf(_tokenId));

        uint256 buyerTotallyEarn = InsuranceFunctions.claimCompensation(
            _tokenId,
            insurances[_epoch]
        );
        (bool success, ) = payable(msg.sender).call{value: buyerTotallyEarn}(
            ""
        );
        if (!success) revert TransferFailed();
    }

    function claimInsurance(uint256 _tokenId, uint256 _epoch) external {
        if (ownerOf(_tokenId) != msg.sender)
            revert NotTokenOwner(msg.sender, ownerOf(_tokenId));

        if (_epoch > epoch) revert InvalidEpoch(_epoch, epoch);

        if (insurances[_epoch].expirationDate >= block.timestamp)
            revert DueTimeNotReached(
                insurances[_epoch].expirationDate,
                block.timestamp
            );

        uint256 sellerTotallyEarn = InsuranceFunctions.claimInsurance(
            _tokenId,
            insurances[_epoch]
        );

        (bool success, ) = payable(msg.sender).call{value: sellerTotallyEarn}(
            ""
        );
        if (!success) revert TransferFailed();
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
        if (_epoch > epoch) revert InvalidEpoch(_epoch, epoch);

        return insurances[_epoch].buyers;
    }

    function getAllSellers(
        uint256 _epoch
    ) public view returns (uint256[] memory) {
        if (_epoch > epoch) revert InvalidEpoch(_epoch, epoch);

        return insurances[_epoch].sellers;
    }

    // TODO: add contract fee
    function withdrawFees() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert TransferFailed();
    }

    // create new insurance
    function startNewEpoch() external onlyOwner {
        uint256 new_epoch = epoch + 1;
        epoch = new_epoch;
        insurances[new_epoch].expirationDate = block.timestamp + duration;
    }

    function setExpirationDate(uint256 _expirationDate) external onlyOwner {
        if (_expirationDate <= block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);

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
