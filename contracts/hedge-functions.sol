// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./hedge-structure.sol";

library HedgeFunctions {
    using Math for uint256;

    function depositRecording(
        uint256 _amount,
        bool isBuyer,
        HedgePool storage pool
    ) internal {
        if (isBuyer) {
            pool.lockedBuyersFundAmount += _amount;
        } else {
            pool.lockedSellersFundAmount += _amount;
        }
    }

    function claimBuyerShares(
        uint256 _amount,
        HedgePool storage pool
    ) internal view returns (uint256) {
        uint256 buyerEarn = _amount.mulDiv(
            pool.lockedSellersFundAmount,
            pool.lockedBuyersFundAmount
        );

        return buyerEarn;
    }

    function claimSellerShares(
        uint256 _amount,
        HedgePool storage pool
    ) internal view returns (uint256) {
        uint256 sellerEarn = _amount.mulDiv(
            pool.lockedBuyersFundAmount,
            pool.lockedSellersFundAmount
        );
        uint256 sellerOwnPart = pool.isCompensatable ? 0 : _amount;

        uint256 sellerTotallyEarn = sellerEarn + sellerOwnPart;

        return sellerTotallyEarn;
    }
}
