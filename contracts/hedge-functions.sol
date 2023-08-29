// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./hedge-structure.sol";

library HedgeFunctions {
    using Math for uint256;

    function depositRecording(
        uint256 _amount,
        bool isBuyer,
        Hedge1155 storage hedge
    ) internal {
        if (isBuyer) {
            hedge.lockedBuyersFundAmount += _amount;
        } else {
            hedge.lockedSellersFundAmount += _amount;
        }
    }

    function claimBuyerShares(
        uint256 _amount,
        Hedge1155 storage hedge
    ) internal view returns (uint256) {
        uint256 buyerEarn = _amount.mulDiv(
            hedge.lockedSellersFundAmount,
            hedge.lockedBuyersFundAmount
        );

        return buyerEarn;
    }

    function claimSellerShares(
        uint256 _amount,
        Hedge1155 storage hedge
    ) internal view returns (uint256) {
        uint256 sellerEarn = _amount.mulDiv(
            hedge.lockedBuyersFundAmount,
            hedge.lockedSellersFundAmount
        );
        uint256 sellerOwnPart = hedge.isCompensatable ? 0 : _amount;

        uint256 sellerTotallyEarn = sellerEarn + sellerOwnPart;

        return sellerTotallyEarn;
    }
}
