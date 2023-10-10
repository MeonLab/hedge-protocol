// HedgeERC1155.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HedgeERC1155 is ERC1155Burnable {
    address public _minter;
    string public _baseURI;

    constructor(
        address minterAddress,
        string memory baseTokenURI
    ) ERC1155(baseTokenURI) {
        _minter = minterAddress;
        _baseURI = baseTokenURI;
    }

    modifier onlyMinter() {
        require(msg.sender == _minter, "Not authorized to mint");
        _;
    }

    function setBaseURI(string memory baseURI) external onlyMinter {
        _baseURI = baseURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
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
