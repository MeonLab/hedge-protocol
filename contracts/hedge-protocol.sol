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
    uint256 public epoch = 0;
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

    function deposit(bool isBuyer, uint256 _epoch) external payable {
        if (_epoch != epoch) revert InvalidEpoch(_epoch, epoch);
        if (hedges[_epoch].depositExpirationDate <= block.timestamp)
            revert PoolLocked();

        uint256 tokenId = _epoch;

        if (isBuyer) {
            buyerToken.mint(msg.sender, tokenId, msg.value, "");
        } else {
            sellerToken.mint(msg.sender, tokenId, msg.value, "");
        }

        HedgeFunctions.depositRecording(msg.value, isBuyer, hedges[_epoch]);
    }

    function setIsCompensatable(uint256 _currentPrice) external onlyOwner {
        if (hedges[epoch].expirationDate <= block.timestamp)
            revert RoundOver(hedges[epoch].expirationDate, block.timestamp);

        if (_currentPrice <= hedges[epoch].liquidationPrice) {
            hedges[epoch].isCompensatable = true;
        }
    }

    function setLiquidationPrices(
        uint256 _liquidationPrices,
        uint256 _epoch
    ) internal {
        if (hedges[_epoch].expirationDate <= block.timestamp)
            revert RoundOver(hedges[_epoch].expirationDate, block.timestamp);

        hedges[_epoch].liquidationPrice = _liquidationPrices;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function setDepositDuration(uint256 _depositDuration) external onlyOwner {
        depositDuration = _depositDuration;
    }

    function claimCompensation(
        uint256 _epoch,
        uint256 tokenID,
        uint256 _amount
    ) external {
        if (_epoch > epoch) revert InvalidEpoch(_epoch, epoch);
        if (hedges[_epoch].isCompensatable != true)
            revert CompensationNotTriggered();
        if (buyerToken.balanceOf(msg.sender, tokenID) < _amount)
            revert NotEnoughBalance(
                buyerToken.balanceOf(msg.sender, tokenID),
                _amount
            );
        if (!buyerToken.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForAll();
        if (tokenID % 2 != 1) revert InvalidTokenId();

        buyerToken.burn(msg.sender, tokenID, _amount); // Burn the ERC1155 tokens
        uint256 compensationAmount = HedgeFunctions.claimBuyerShares(
            _amount,
            hedges[_epoch]
        );

        clientWithdraw(compensationAmount);
    }

    function claimInsurance(
        uint256 _epoch,
        uint256 tokenID,
        uint256 _amount
    ) external {
        if (_epoch > epoch) revert InvalidEpoch(_epoch, epoch);

        if (hedges[_epoch].expirationDate >= block.timestamp)
            revert DueTimeNotReached(
                hedges[_epoch].expirationDate,
                block.timestamp
            );

        if (sellerToken.balanceOf(msg.sender, tokenID) < _amount)
            revert NotEnoughBalance(
                sellerToken.balanceOf(msg.sender, tokenID),
                _amount
            );

        if (!sellerToken.isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForAll();

        if (tokenID % 2 != 0) revert InvalidTokenId(); // seller

        sellerToken.burn(msg.sender, _epoch, _amount); // Burn the ERC1155 tokens

        uint256 insuranceAmount = HedgeFunctions.claimSellerShares(
            _amount,
            hedges[_epoch]
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
    function startNewEpoch(uint256 _liquidationPrices) external onlyOwner {
        uint256 newEpoch = epoch + 1;
        epoch = newEpoch;
        hedges[newEpoch].expirationDate = block.timestamp + duration;
        hedges[newEpoch].depositExpirationDate =
            block.timestamp +
            depositDuration;
        setLiquidationPrices(_liquidationPrices, newEpoch);
    }

    function setExpirationDate(uint256 _expirationDate) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        hedges[epoch].expirationDate = _expirationDate;
    }

    function setDepositExpirationDate(
        uint256 _expirationDate
    ) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        hedges[epoch].depositExpirationDate = _expirationDate;
    }

    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function isEpochDepositOver(uint _epoch) external view returns (bool) {
        return hedges[_epoch].depositExpirationDate < block.timestamp;
    }

    function isEpochExpired(uint _epoch) external view returns (bool) {
        return hedges[_epoch].expirationDate < block.timestamp;
    }

    receive() external payable {}

    fallback() external payable {}
}
