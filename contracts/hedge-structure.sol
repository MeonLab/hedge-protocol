// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct HedgePool {
    mapping(uint256 => uint256) buyersPool;
    mapping(uint256 => uint256) sellersPool;
    // TODO: move to EpochCollectionHedge1155?
    // uint256[] buyers;
    // uint256[] sellers;
    uint256 lockedSellersFundAmount;
    uint256 lockedBuyersFundAmount;
    uint256 liquidationPrice;
    uint256 expirationDate;
    uint256 depositExpirationDate;
    bool isCompensatable;
}
