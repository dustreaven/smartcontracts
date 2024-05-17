// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Martex

interface ISwingSwap {
    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut);
}

contract FeeChargingSwap {
    address public owner;
    ISwingSwap public swingSwap;
    
    uint256 public feePercent = 3;

    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event FeeCollected(address indexed user, uint256 feeAmount);

    constructor(address _swingSwapAddress) {
        owner = msg.sender;
        swingSwap = ISwingSwap(_swingSwapAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function setFeePercent(uint256 _feePercent) external onlyOwner {
        require(_feePercent <= 100, "Fee percent too high");
        feePercent = _feePercent;
    }

    function swapWithFee(address tokenIn, address tokenOut, uint256 amountIn) external {
        uint256 feeAmount = (amountIn * feePercent) / 100;
        uint256 amountAfterFee = amountIn - feeAmount;

        // Transfer tokens from user to contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve SwingSwap to spend tokens
        IERC20(tokenIn).approve(address(swingSwap), amountAfterFee);

        // Execute the swap
        uint256 amountOut = swingSwap.swapTokens(tokenIn, tokenOut, amountAfterFee);

        // Transfer output tokens back to the user
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        // Emit events
        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        emit FeeCollected(msg.sender, feeAmount);
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
