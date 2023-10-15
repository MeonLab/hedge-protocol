// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library HedgeLogs {
    event Deposit(bool isBuyer, uint256 value);

    error InvalidRound(uint256 provided, uint256 current);
    error NotEnoughBalance(uint256 balance, uint256 amount);
    error NotApprovedForAll();
    error PoolLocked();

    error RoundOver(uint256 expirationDate, uint256 currentTime);
    error CompensationNotTriggered();
    error DueTimeNotReached(uint256 expirationDate, uint256 currentTime);
    error TransferFailed();
    error InvalidExpirationDate(uint256 expirationDate, uint256 currentTime);
    error InvalidTokenId();

    error PoolDuplicated();
}
