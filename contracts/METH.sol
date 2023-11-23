pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract METH is ERC20, Ownable {
    mapping(address => bool) public hasMinted;
    address[] public allowedContracts;

    constructor() ERC20("MeonETH", "METH") {}

    function mint() public {
        require(!hasMinted[msg.sender], "Already minted");
        _mint(msg.sender, 10000 * (10 ** uint256(decimals())));
        hasMinted[msg.sender] = true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(
            isAllowedContract(to) || isAllowedContract(msg.sender),
            "Transfers restricted"
        );
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(
            isAllowedContract(to) || isAllowedContract(from),
            "Transfers restricted"
        );
        return super.transferFrom(from, to, amount);
    }

    function isAllowedContract(address _address) internal view returns (bool) {
        for (uint i = 0; i < allowedContracts.length; i++) {
            if (allowedContracts[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function addAllowedContract(address _newContract) public onlyOwner {
        require(_newContract != address(0), "Invalid address");
        allowedContracts.push(_newContract);
    }

    function removeAllowedContract(address _contract) public onlyOwner {
        require(_contract != address(0), "Invalid address");
        for (uint i = 0; i < allowedContracts.length; i++) {
            if (allowedContracts[i] == _contract) {
                allowedContracts[i] = allowedContracts[
                    allowedContracts.length - 1
                ];
                allowedContracts.pop();
                break;
            }
        }
    }
}
