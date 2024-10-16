// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract saToken is ERC20 {
    address public protocol;   // Protocol address that can mint, burn, and rebase
    uint256 public totalInterest;  // Tracks the total interest accrued by the token

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Not protocol");
        _;
    }

    // Constructor that initializes the token with name, symbol, and sets the protocol address
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        protocol = msg.sender;  // Assign the contract deployer as the protocol
    }

    // Mint new tokens, only callable by the protocol
    function mint(address to, uint256 amount) external onlyProtocol {
        _mint(to, amount);
    }

    // Burn tokens from a user's balance, only callable by the protocol
    function burn(address from, uint256 amount) external onlyProtocol {
        _burn(from, amount);
    }

    // Rebase function to simulate interest accrual by minting additional tokens
    function rebase(uint256 interest) external onlyProtocol {
        require(interest > 0, "Interest must be greater than 0");

        totalInterest += interest;
        _mint(address(this), interest);  // Mint the interest to the contract address
    }

    // Withdraw function for users to redeem tokens
    // Here, it's assumed that the logic for transferring the underlying asset (USDC, ETH, MATIC) will be added
    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);  // Burn the user's tokens
        
        // Add logic to transfer the corresponding asset (USDC, ETH, or MATIC)
        // If the asset is ETH or MATIC, it will be a direct transfer using `payable(address(this)).transfer(amount);`
        // If USDC, it would use `IERC20(tokenAddress).transfer(msg.sender, amount);`
    }

    // Fallback function to receive ETH or MATIC if needed
    receive() external payable {}
}
