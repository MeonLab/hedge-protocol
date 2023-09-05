// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./HedgeERC1155.sol";
import "./hedge-error.sol";
import "./hedge-structure.sol";
import "./hedge-functions.sol";

// TODO: Add events
contract NftHedgeProtocol is Ownable, ReentrancyGuard {
    using Math for uint256;

    // TODO: duration should be set a real value
    address public vaultAddress;
    HedgeERC1155 public buyerToken;
    HedgeERC1155 public sellerToken;
    mapping(uint256 => Hedge1155) public hedges;
    uint256 public currRoundID = 0;
    uint256 public duration = 600;
    uint256 public depositDuration = 60;

    constructor(address _vaultAddress) {
        buyerToken = new HedgeERC1155("HedgeBuyerToken", address(this));
        sellerToken = new HedgeERC1155("HedgeSellerToken", address(this));
        vaultAddress = _vaultAddress;
    }

    // TODO: set "_uri", overwrite uri function
    // function _exists(uint256 tokenId) internal view returns (bool) {
    //     return _balances[tokenId] > 0;
    // }

    // // setting token uri
    // function setURI(uint256 tokenId, string memory newURI) public {
    //     require(_exists(tokenId), "ERC1155: URI set of nonexistent token");
    //     _tokenURIs[tokenId] = newURI;
    // }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function deposit(bool isBuyer) external payable {
        if (hedges[currRoundID].depositExpirationDate <= block.timestamp)
            revert PoolLocked();

        uint256 tokenId = currRoundID;

        if (isBuyer) {
            buyerToken.mint(msg.sender, tokenId, msg.value, "");
        } else {
            sellerToken.mint(msg.sender, tokenId, msg.value, "");
        }

        HedgeFunctions.depositRecording(
            msg.value,
            isBuyer,
            hedges[currRoundID]
        );
    }

    function setIsCompensatable(uint256 _currentPrice) external onlyOwner {
        if (hedges[currRoundID].expirationDate <= block.timestamp)
            revert RoundOver(
                hedges[currRoundID].expirationDate,
                block.timestamp
            );

        if (_currentPrice <= hedges[currRoundID].liquidationPrice) {
            hedges[currRoundID].isCompensatable = true;
        }
    }

    function setLiquidationPrices(uint256 _liquidationPrices) internal {
        if (hedges[currRoundID].expirationDate <= block.timestamp)
            revert RoundOver(
                hedges[currRoundID].expirationDate,
                block.timestamp
            );

        hedges[currRoundID].liquidationPrice = _liquidationPrices;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function setDepositDuration(uint256 _depositDuration) external onlyOwner {
        depositDuration = _depositDuration;
    }

    function claimCompensation(
        // uint256 roundID,
        uint256 tokenID,
        uint256 _amount
    ) external {
        // the tokenID is the round id for that turn.
        if (tokenID > currRoundID) revert InvalidRound(tokenID, currRoundID);
        if (hedges[tokenID].isCompensatable != true)
            revert CompensationNotTriggered();
        if (buyerToken.balanceOf(msg.sender, tokenID) < _amount)
            revert NotEnoughBalance(
                buyerToken.balanceOf(msg.sender, tokenID),
                _amount
            );
        if (!buyerToken.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForAll();

        buyerToken.burn(msg.sender, tokenID, _amount); // Burn the ERC1155 tokens
        uint256 compensationAmount = HedgeFunctions.claimBuyerShares(
            _amount,
            hedges[tokenID]
        );

        clientWithdraw(compensationAmount);
    }

    function claimInsurance(
        // uint256 roundID,
        uint256 tokenID,
        uint256 _amount
    ) external {
        if (tokenID > currRoundID) revert InvalidRound(tokenID, currRoundID);

        if (hedges[tokenID].expirationDate >= block.timestamp)
            revert DueTimeNotReached(
                hedges[tokenID].expirationDate,
                block.timestamp
            );

        if (sellerToken.balanceOf(msg.sender, tokenID) < _amount)
            revert NotEnoughBalance(
                sellerToken.balanceOf(msg.sender, tokenID),
                _amount
            );

        if (!sellerToken.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForAll();

        sellerToken.burn(msg.sender, tokenID, _amount); // Burn the ERC1155 tokens

        uint256 insuranceAmount = HedgeFunctions.claimSellerShares(
            _amount,
            hedges[tokenID]
        );

        clientWithdraw(insuranceAmount);
    }

    function clientWithdraw(uint256 amount) internal {
        uint256 fee = amount / 100;
        uint256 payoutAmount = amount - fee;

        (bool vaultSuccess, ) = payable(vaultAddress).call{value: fee}("");
        if (!vaultSuccess) revert TransferFailed();

        (bool userSuccess, ) = payable(msg.sender).call{value: payoutAmount}(
            ""
        );
        if (!userSuccess) revert TransferFailed();
    }

    // TODO: withdraw all

    // create new insurance
    function startNewRound(uint256 _liquidationPrices) external onlyOwner {
        if (hedges[currRoundID].expirationDate >= block.timestamp)
            revert PoolDuplicated();
        uint256 newRoundID = currRoundID + 1;
        currRoundID = newRoundID;
        hedges[currRoundID].expirationDate = block.timestamp + duration;
        hedges[currRoundID].depositExpirationDate =
            block.timestamp +
            depositDuration;
        setLiquidationPrices(_liquidationPrices);
    }

    function setExpirationDate(uint256 _expirationDate) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        hedges[currRoundID].expirationDate = _expirationDate;
    }

    function setDepositExpirationDate(
        uint256 _expirationDate
    ) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        hedges[currRoundID].depositExpirationDate = _expirationDate;
    }

    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function isRoundDepositOver(uint _roundID) external view returns (bool) {
        return hedges[_roundID].depositExpirationDate < block.timestamp;
    }

    function isRoundExpired(uint _roundID) external view returns (bool) {
        return hedges[_roundID].expirationDate < block.timestamp;
    }

    receive() external payable {}

    fallback() external payable {}
}
