error InvalidEpoch(uint256 provided, uint256 current);
error NotTokenOwner(address caller, address owner);
error PoolLocked();
error CurrentPriceNotLessThanCompensationPrice(
    uint256 currentPrice,
    uint256 compensationPrice
);
error InsuranceOver(uint256 expirationDate, uint256 currentTime);
error CompensationNotTriggered();
error DueTimeNotReached(uint256 expirationDate, uint256 currentTime);
error TransferFailed();
error InvalidExpirationDate(uint256 expirationDate, uint256 currentTime);
