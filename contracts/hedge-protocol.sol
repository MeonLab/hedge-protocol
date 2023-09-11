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
import "@openzeppelin/contracts/utils/Strings.sol";

// TODO: Add events
contract NftHedgeProtocol is Ownable, ReentrancyGuard {
    using Math for uint256;

    address public vaultAddress;
    string public hedgeTarget;
    HedgeERC1155 public buyerToken;
    HedgeERC1155 public sellerToken;
    mapping(uint256 => HedgePool) public pools;
    uint256 public currRoundID = 0;
    uint256 public duration = 300;
    uint256 public depositDuration = 200;

    constructor(address _vaultAddress, string memory _hedgeTarget) {
        vaultAddress = _vaultAddress;
        hedgeTarget = _hedgeTarget;
        // buyerToken = new HedgeERC1155("HedgeBuyerToken", address(this));
        // sellerToken = new HedgeERC1155("HedgeSellerToken", address(this));
        buyerToken = new HedgeERC1155(
            string(
                abi.encodePacked(
                    "https://meon.finance/",
                    Strings.toHexString(address(this)),
                    "/buyer/"
                )
            ),
            address(this)
        );
        sellerToken = new HedgeERC1155(
            string(
                abi.encodePacked(
                    "https://meon.finance/",
                    Strings.toHexString(address(this)),
                    "/seller/"
                )
            ),
            address(this)
        );
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function setERC1155URIs(string memory newURI) external onlyOwner {
        buyerToken.setBaseURI(string(abi.encodePacked(newURI, "/buyer/")));
        sellerToken.setBaseURI(string(abi.encodePacked(newURI, "/seller/")));
    }

    function deposit(bool isBuyer) external payable {
        if (pools[currRoundID].depositExpirationDate <= block.timestamp)
            revert PoolLocked();

        uint256 tokenId = currRoundID;

        if (isBuyer) {
            buyerToken.mint(msg.sender, tokenId, msg.value, "");
        } else {
            sellerToken.mint(msg.sender, tokenId, msg.value, "");
        }

        HedgeFunctions.depositRecording(msg.value, isBuyer, pools[currRoundID]);
    }

    function setIsCompensatable(uint256 _currentPrice) external onlyOwner {
        if (pools[currRoundID].expirationDate <= block.timestamp)
            revert RoundOver(
                pools[currRoundID].expirationDate,
                block.timestamp
            );

        if (_currentPrice <= pools[currRoundID].liquidationPrice) {
            pools[currRoundID].isCompensatable = true;
        }
    }

    function setLiquidationPrices(uint256 _liquidationPrices) internal {
        if (pools[currRoundID].expirationDate <= block.timestamp)
            revert RoundOver(
                pools[currRoundID].expirationDate,
                block.timestamp
            );

        pools[currRoundID].liquidationPrice = _liquidationPrices;
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
        if (pools[tokenID].isCompensatable != true)
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
            pools[tokenID]
        );

        clientWithdraw(compensationAmount);
    }

    function claimInsurance(
        // uint256 roundID,
        uint256 tokenID,
        uint256 _amount
    ) external {
        if (tokenID > currRoundID) revert InvalidRound(tokenID, currRoundID);

        if (pools[tokenID].expirationDate >= block.timestamp)
            revert DueTimeNotReached(
                pools[tokenID].expirationDate,
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
            pools[tokenID]
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
        if (pools[currRoundID].expirationDate >= block.timestamp)
            revert PoolDuplicated();
        uint256 newRoundID = currRoundID + 1;
        currRoundID = newRoundID;
        pools[currRoundID].expirationDate = block.timestamp + duration;
        pools[currRoundID].depositExpirationDate =
            block.timestamp +
            depositDuration;
        setLiquidationPrices(_liquidationPrices);
    }

    function setExpirationDate(uint256 _expirationDate) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        pools[currRoundID].expirationDate = _expirationDate;
    }

    function setDepositExpirationDate(
        uint256 _expirationDate
    ) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        pools[currRoundID].depositExpirationDate = _expirationDate;
    }

    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function isRoundDepositOver(uint _roundID) external view returns (bool) {
        return pools[_roundID].depositExpirationDate < block.timestamp;
    }

    function isRoundExpired(uint _roundID) external view returns (bool) {
        return pools[_roundID].expirationDate < block.timestamp;
    }

    function getCurrentRoundInfo()
        external
        view
        returns (
            uint256 lockedSellersFundAmount,
            uint256 lockedBuyersFundAmount,
            uint256 liquidationPrice,
            uint256 expirationDate,
            uint256 depositExpirationDate,
            bool isCompensatable
        )
    {
        lockedSellersFundAmount = pools[currRoundID].lockedSellersFundAmount;
        lockedBuyersFundAmount = pools[currRoundID].lockedBuyersFundAmount;
        liquidationPrice = pools[currRoundID].liquidationPrice;
        expirationDate = pools[currRoundID].expirationDate;
        depositExpirationDate = pools[currRoundID].depositExpirationDate;
        isCompensatable = pools[currRoundID].isCompensatable;
    }

    function getRoundInfo(
        uint256 roundID
    )
        external
        view
        returns (
            uint256 lockedSellersFundAmount,
            uint256 lockedBuyersFundAmount,
            uint256 liquidationPrice,
            uint256 expirationDate,
            uint256 depositExpirationDate,
            bool isCompensatable
        )
    {
        require(roundID <= currRoundID, "Round ID is not valid");

        lockedSellersFundAmount = pools[roundID].lockedSellersFundAmount;
        lockedBuyersFundAmount = pools[roundID].lockedBuyersFundAmount;
        liquidationPrice = pools[roundID].liquidationPrice;
        expirationDate = pools[roundID].expirationDate;
        depositExpirationDate = pools[roundID].depositExpirationDate;
        isCompensatable = pools[roundID].isCompensatable;
    }

    function getTokensOwnedByAddress(
        address userAddress
    )
        external
        view
        returns (
            uint256[] memory buyerBalances,
            uint256[] memory sellerBalances
        )
    {
        buyerBalances = new uint256[](currRoundID + 1);
        sellerBalances = new uint256[](currRoundID + 1);

        for (uint256 i = 0; i <= currRoundID; i++) {
            buyerBalances[i] = buyerToken.balanceOf(userAddress, i);
            sellerBalances[i] = sellerToken.balanceOf(userAddress, i);
        }
    }

    function getBuyerTokenURI(
        uint256 tokenId
    ) public view returns (string memory) {
        return buyerToken.uri(tokenId);
    }

    function getSellerTokenURI(
        uint256 tokenId
    ) public view returns (string memory) {
        return sellerToken.uri(tokenId);
    }

    receive() external payable {}

    fallback() external payable {}
}
