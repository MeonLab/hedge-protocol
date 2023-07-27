pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./insurance-structure.sol";

library InsuranceFunctions1155 {
    using Math for uint256;

    function depositRecording(
        uint256 _amount,
        bool isBuyer,
        Insurance1155 storage insurance
    ) internal {
        if (isBuyer) {
            insurance.lockedBuyersFundAmount += _amount;
            insurance.buyersFundAmount += _amount;
        } else {
            insurance.sellersFundAmount += _amount;
            insurance.lockedSellersFundAmount += _amount;
        }
    }

    function claimCompensation(
        uint256 _amount,
        Insurance1155 storage insurance
    ) internal returns (uint256) {
        uint256 buyerEarn = _amount.mulDiv(
            insurance.lockedSellersFundAmount,
            insurance.lockedBuyersFundAmount
        );

        // update sellersFundAmount
        insurance.sellersFundAmount = insurance.sellersFundAmount - buyerEarn;

        return buyerEarn;
    }

    function claimInsurance(
        uint256 _amount,
        Insurance1155 storage insurance
    ) internal returns (uint256) {
        uint256 sellerEarn = _amount.mulDiv(
            insurance.lockedBuyersFundAmount,
            insurance.lockedSellersFundAmount
        );
        uint256 sellerOwnPart = insurance.isCompensatable ? 0 : _amount;

        uint256 sellerTotallyEarn = sellerEarn + sellerOwnPart;

        // update buyersFundAmount
        insurance.buyersFundAmount = insurance.buyersFundAmount - sellerEarn;

        // update sellersFundAmount
        insurance.sellersFundAmount =
            insurance.sellersFundAmount -
            sellerOwnPart;

        return sellerTotallyEarn;
    }
}
