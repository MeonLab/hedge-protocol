import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HedgeVault is Ownable {
    event FeeReceived(address indexed token, address from, uint256 amount);
    event FeeWithdrawn(address indexed token, address to, uint256 amount);

    // Withdraw Ether
    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed");
        emit FeeWithdrawn(address(0), owner(), amount);
    }

    // Withdraw ERC20 Tokens
    function withdrawToken(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(token.transfer(owner(), amount), "Token transfer failed");
        emit FeeWithdrawn(address(token), owner(), amount);
    }

    // Get the balance of Ether in the vault
    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Get the balance of a specific ERC20 token in the vault
    function getTokenBalance(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // No need for receive() and fallback() for ERC20, as ERC20 tokens are not sent via direct transfer
}
