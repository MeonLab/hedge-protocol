// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HedgeVault is Ownable {
    event FeeReceived(address from, uint256 amount);
    event FeeWithdrawn(address to, uint256 amount);

    // Only the owner can withdraw the fees.
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        // Use call() to send the Ether and check its return value.
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed");

        emit FeeWithdrawn(msg.sender, amount);
    }

    // Getter to check the balance of the vault
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit FeeReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FeeReceived(msg.sender, msg.value);
    }
}
