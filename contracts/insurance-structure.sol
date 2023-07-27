// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Insurance1155 {
    mapping(uint256 => uint256) buyersPool;
    mapping(uint256 => uint256) sellersPool;
    // TODO: move to EpochCollectionHedge1155?
    uint256[] buyers;
    uint256[] sellers;
    uint256 sellersFundAmount;
    uint256 buyersFundAmount;
    uint256 lockedSellersFundAmount;
    uint256 lockedBuyersFundAmount;
    uint256 currentPrice;
    uint256 liquidationPrice;
    uint256 expirationDate;
    uint256 depositExpirationDate;
    bool isCompensatable;
}
