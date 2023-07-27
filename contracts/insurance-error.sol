error InvalidEpoch(uint256 provided, uint256 current);
error NotEnoughBalance(uint256 balance, uint256 amount);
error NotApprovedForAll();
error PoolLocked();

error InsuranceOver(uint256 expirationDate, uint256 currentTime);
error CompensationNotTriggered();
error DueTimeNotReached(uint256 expirationDate, uint256 currentTime);
error TransferFailed();
error InvalidExpirationDate(uint256 expirationDate, uint256 currentTime);
error InvalidTokenId();
