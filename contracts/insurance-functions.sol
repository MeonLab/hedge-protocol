pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./insurance-structure.sol";

library InsuranceFunctions {
    using Math for uint256;

    function deposit(
        uint256 _tokenId,
        uint256 _amount,
        bool isBuyer,
        Insurance storage insurance
    ) internal {
        if (isBuyer) {
            insurance.buyersPool[_tokenId] = _amount;
            insurance.buyersFundAmount += _amount;
            insurance.buyers.push(_tokenId);
        } else {
            insurance.sellersPool[_tokenId] = _amount;
            insurance.sellersFundAmount += _amount;
            insurance.sellers.push(_tokenId);
        }
    }

    function claimCompensation(
        uint256 _tokenId,
        Insurance storage insurance
    ) internal returns (uint256) {
        uint256 buyerOwnPart = insurance.buyersPool[_tokenId];
        uint256 buyerTotallyEarn = buyerOwnPart.mulDiv(
            insurance.lockedSellersFundAmount,
            insurance.lockedBuyersFundAmount
        );

        // update sellersFundAmount
        insurance.sellersFundAmount =
            insurance.sellersFundAmount -
            buyerTotallyEarn;

        return buyerTotallyEarn;
    }

    function claimInsurance(
        uint256 _tokenId,
        Insurance storage insurance
    ) internal returns (uint256) {
        uint256 sellerOwnPart = insurance.sellersPool[_tokenId];
        uint256 sellerEarn = sellerOwnPart.mulDiv(
            insurance.lockedBuyersFundAmount,
            insurance.lockedSellersFundAmount
        );

        if (insurance.isCompensatable == true) {
            sellerOwnPart = 0;
        }

        uint256 sellerTotallyEarn = sellerEarn + sellerOwnPart;

        // update buyersFundAmount
        insurance.buyersFundAmount = insurance.buyersFundAmount - sellerEarn;

        // update sellersFundAmount
        insurance.sellersFundAmount =
            insurance.sellersFundAmount -
            sellerOwnPart;

        insurance.sellersPool[_tokenId] = 0;

        return sellerTotallyEarn;
    }
}
