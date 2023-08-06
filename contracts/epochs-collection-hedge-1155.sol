pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./insurance-error.sol";
import "./insurance-structure.sol";
import "./insurance-functions.sol";

contract EpochCollectionHedge1155 is
    Ownable,
    ReentrancyGuard,
    ERC1155("NFTHedge")
{
    using Math for uint256;

    // TODO: duration should be set a real value
    mapping(uint256 => Insurance1155) public insurances;
    uint256 public epoch = 0;
    uint256 public duration = 600;
    uint256 public depositDuration = 60;

    // TODO: set "_uri", overwrite uri function
    // function _exists(uint256 tokenId) internal view returns (bool) {
    //     return _balances[tokenId] > 0;
    // }

    // // setting token uri
    // function setURI(uint256 tokenId, string memory newURI) public {
    //     require(_exists(tokenId), "ERC1155: URI set of nonexistent token");
    //     _tokenURIs[tokenId] = newURI;
    // }

    // each epoch has different token id, buyer is odd, seller is even
    function deposit(bool isBuyer, uint256 _epoch) external payable {
        if (_epoch != epoch) revert InvalidEpoch(_epoch, epoch);
        if (insurances[_epoch].depositExpirationDate <= block.timestamp)
            revert PoolLocked();

        uint256 tokenId = _epoch * 2 + (isBuyer ? 1 : 0);
        _mint(msg.sender, tokenId, msg.value, "");
        InsuranceFunctions1155.depositRecording(
            msg.value,
            isBuyer,
            insurances[_epoch]
        );
    }

    function setCurrentPrices(
        uint256 _currentPrice,
        uint256 _epoch
    ) external onlyOwner {
        if (insurances[_epoch].expirationDate <= block.timestamp)
            revert InsuranceOver(
                insurances[_epoch].expirationDate,
                block.timestamp
            );

        if (_currentPrice <= insurances[_epoch].liquidationPrice) {
            insurances[_epoch].isCompensatable = true;
        }
    }

    function setLiquidationPrices(
        uint256 _liquidationPrices,
        uint256 _epoch
    ) internal {
        if (insurances[_epoch].expirationDate <= block.timestamp)
            revert InsuranceOver(
                insurances[_epoch].expirationDate,
                block.timestamp
            );

        insurances[_epoch].liquidationPrice = _liquidationPrices;
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
        if (insurances[_epoch].isCompensatable != true)
            revert CompensationNotTriggered();
        if (balanceOf(msg.sender, tokenID) < _amount)
            revert NotEnoughBalance(balanceOf(msg.sender, tokenID), _amount);
        if (!isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForAll();
        if (tokenID % 2 != 1) revert InvalidTokenId();

        _burn(msg.sender, tokenID, _amount); // Burn the ERC1155 tokens
        uint256 compensationAmount = InsuranceFunctions1155.claimCompensation(
            _amount,
            insurances[_epoch]
        );
        (bool success, ) = payable(msg.sender).call{value: compensationAmount}(
            ""
        );
        if (!success) revert TransferFailed();
    }

    function claimInsurance(
        uint256 _epoch,
        uint256 tokenID,
        uint256 _amount
    ) external {
        if (_epoch > epoch) revert InvalidEpoch(_epoch, epoch);

        if (insurances[_epoch].expirationDate >= block.timestamp)
            revert DueTimeNotReached(
                insurances[_epoch].expirationDate,
                block.timestamp
            );

        if (balanceOf(msg.sender, tokenID) < _amount)
            revert NotEnoughBalance(balanceOf(msg.sender, tokenID), _amount);

        if (!isApprovedForAll(msg.sender, address(this)))
            revert NotApprovedForAll();

        if (tokenID % 2 != 0) revert InvalidTokenId(); // seller

        _burn(msg.sender, _epoch, _amount); // Burn the ERC1155 tokens

        uint256 insuranceAmount = InsuranceFunctions1155.claimInsurance(
            _amount,
            insurances[_epoch]
        );

        (bool success, ) = payable(msg.sender).call{value: insuranceAmount}("");
        if (!success) revert TransferFailed();
    }

    // TODO: add contract fee
    function withdrawFees() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert TransferFailed();
    }

    // create new insurance
    function startNewEpoch(uint256 _liquidationPrices) external onlyOwner {
        uint256 newEpoch = epoch + 1;
        epoch = newEpoch;
        insurances[new_epoch].expirationDate = block.timestamp + duration;
        insurances[new_epoch].depositExpirationDate =
            block.timestamp +
            depositDuration;
        setLiquidationPrices(_liquidationPrices, newEpoch);
    }

    function setExpirationDate(uint256 _expirationDate) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        insurances[epoch].expirationDate = _expirationDate;
    }

    function setDepositExpirationDate(
        uint256 _expirationDate
    ) external onlyOwner {
        if (_expirationDate > block.timestamp)
            revert InvalidExpirationDate(_expirationDate, block.timestamp);
        insurances[epoch].depositExpirationDate = _expirationDate;
    }

    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function isEpochDepositOver(uint _epoch) external view returns (bool) {
        return insurances[_epoch].depositExpirationDate < block.timestamp;
    }

    function isEpochExpired(uint _epoch) external view returns (bool) {
        return insurances[_epoch].expirationDate < block.timestamp;
    }

    receive() external payable {}

    fallback() external payable {}
}
