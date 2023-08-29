// HedgeERC1155.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract HedgeERC1155 is ERC1155Burnable {
    address private _minter;

    constructor(string memory uri, address minterAddress) ERC1155(uri) {
        _minter = minterAddress;
    }

    modifier onlyMinter() {
        require(msg.sender == _minter, "Not authorized to mint");
        _;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyMinter {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyMinter {
        _mintBatch(to, ids, amounts, data);
    }
}
