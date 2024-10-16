// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/contracts/LendingProtocol.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingProtocolTest is Test {
    LendingProtocol protocol;
    address public lender = address(0x123);
    address public borrower = address(0x456);
    
    // Token addresses for testing
    address public USDC = address(0x111);
    address public ETH = address(0x222);
    address public MATIC = address(0x333);

    // Amounts for testing
    uint256 public depositAmount = 1000 * 10**6; // For USDC, assuming 6 decimals
    uint256 public rebaseAmount = 100 * 10**6; // Rebase interest in USDC
    uint256 public redeemAmount = 500 * 10**6; // Amount to redeem from saUSDC

    function setUp() public {
        // Deploy the LendingProtocol contract
        protocol = new LendingProtocol();

        // Add necessary mock tokens or setup existing token addresses if available
        // We assume USDC, ETH, MATIC tokens are pre-deployed for testing purposes
        // The mock tokens would need to have appropriate mint and transfer functions

        // Mock the behavior of the tokens or provide initial balances if using real tokens
    }

    function testDepositUSDC() public {
        // Simulate the USDC deposit
        vm.prank(lender); // Set the context for the lender
        protocol.deposit(USDC, depositAmount); // Lender deposits USDC

        // Validate that the lender received the correct saToken (saUSDC)
        uint256 saUSDCBalance = protocol.saUSDC().balanceOf(lender);
        assertEq(saUSDCBalance, depositAmount, "Lender should have received correct saUSDC amount");
    }

    function testRebase() public {
        // Simulate a rebase by depositing more funds
        vm.prank(address(protocol)); // Set the context to the protocol
        protocol.triggerRebase(rebaseAmount, USDC); // Trigger a rebase on saUSDC

        // Validate that the rebase has been triggered and interest has been added
        uint256 saUSDCBalance = protocol.saUSDC().totalSupply(); // Check the total supply of saUSDC
        assertEq(saUSDCBalance, rebaseAmount, "Total supply of saUSDC should have increased after rebase");
    }

    function testRedeem() public {
        // First deposit tokens to simulate receiving saTokens
        vm.prank(lender);
        protocol.deposit(USDC, depositAmount);

        // Simulate the lender redeeming their saTokens
        vm.prank(lender); // Set the context for the lender
        protocol.redeem(USDC, redeemAmount); // Redeem saUSDC

        // Validate that the lender now has received their underlying USDC
        uint256 lenderUSDCBalance = IERC20(USDC).balanceOf(lender);
        assertEq(lenderUSDCBalance, redeemAmount, "Lender should have received their underlying USDC");

        // Validate that the redeemed saToken amount has been burned
        uint256 saUSDCBalance = protocol.saUSDC().balanceOf(lender);
        assertEq(saUSDCBalance, depositAmount - redeemAmount, "Lender should have remaining saUSDC after redemption");
    }
}
