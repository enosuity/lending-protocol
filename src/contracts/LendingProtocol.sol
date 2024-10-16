// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./saToken.sol";

contract LendingProtocol {
    // Track deposits by lender address and token type
    mapping(address => mapping(address => uint256)) public deposits;
    // Track the protocol's internal tokens (saUSDC, saETH, saMATIC)
    saToken public saUSDC;
    saToken public saETH;
    saToken public saMATIC;
    
    // Emitted when a lender deposits assets into the protocol
    event Deposited(address indexed lender, address indexed token, uint256 amount, uint256 mintedAmount);
    // Emitted when a lender redeems saTokens for the underlying asset
    event Redeemed(address indexed lender, address indexed token, uint256 saTokenAmount, uint256 returnedAmount);
    // Emitted when the protocol rebases the tokens
    event Rebased(address indexed token, uint256 newInterest, uint256 totalSupply);
    
    // Constructor to initialize saTokens for USDC, ETH, and MATIC
    constructor() {
        saUSDC = new saToken("Stable USDC", "saUSDC");
        saETH = new saToken("Stable ETH", "saETH");
        saMATIC = new saToken("Stable MATIC", "saMATIC");
    }

    // Function for lenders to deposit USDC, ETH, or MATIC and receive the corresponding saToken
    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(token == address(0) || token == address(saUSDC) || token == address(saETH) || token == address(saMATIC), "Invalid token");

        // Deposit the asset into the protocol
        if (token == address(saUSDC)) {
            // Transfer USDC from the lender to the protocol
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
            // Mint saUSDC tokens for the lender
            saUSDC.mint(msg.sender, amount);
            deposits[msg.sender][token] += amount;
        } else if (token == address(saETH)) {
            // Transfer ETH from the lender to the protocol
            require(msg.sender.balance >= amount, "Insufficient ETH balance");
            payable(address(this)).transfer(amount);
            // Mint saETH tokens for the lender
            saETH.mint(msg.sender, amount);
            deposits[msg.sender][token] += amount;
        } else if (token == address(saMATIC)) {
            // Transfer MATIC from the lender to the protocol
            require(msg.sender.balance >= amount, "Insufficient MATIC balance");
            payable(address(this)).transfer(amount);
            // Mint saMATIC tokens for the lender
            saMATIC.mint(msg.sender, amount);
            deposits[msg.sender][token] += amount;
        }

        emit Deposited(msg.sender, token, amount, amount);
    }

    // Function for lenders to redeem saTokens for the corresponding asset (USDC, ETH, or MATIC)
    function redeem(address token, uint256 amount) external {
        require(amount > 0, "Redeem amount must be greater than 0");
        require(deposits[msg.sender][token] >= amount, "Insufficient balance");

        // Burn saTokens and transfer the underlying asset back to the lender
        if (token == address(saUSDC)) {
            saUSDC.burn(msg.sender, amount);
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
            deposits[msg.sender][token] -= amount;
        } else if (token == address(saETH)) {
            saETH.burn(msg.sender, amount);
            payable(msg.sender).transfer(amount);
            deposits[msg.sender][token] -= amount;
        } else if (token == address(saMATIC)) {
            saMATIC.burn(msg.sender, amount);
            payable(msg.sender).transfer(amount);
            deposits[msg.sender][token] -= amount;
        }

        emit Redeemed(msg.sender, token, amount, amount);
    }

    // Function to simulate interest accrual and rebase the tokens
    function triggerRebase(uint256 interest, address token) external {
        require(interest > 0, "Interest must be greater than 0");
        require(token == address(saUSDC) || token == address(saETH) || token == address(saMATIC), "Invalid token");

        // Rebase the corresponding token by calling the rebase function
        if (token == address(saUSDC)) {
            saUSDC.rebase(interest);
        } else if (token == address(saETH)) {
            saETH.rebase(interest);
        } else if (token == address(saMATIC)) {
            saMATIC.rebase(interest);
        }

        emit Rebased(token, interest, IERC20(token).totalSupply());
    }

    // Fallback function to accept ETH and MATIC directly
    receive() external payable {}
}
