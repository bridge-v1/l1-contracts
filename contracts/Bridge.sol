// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract Bridge {
    struct Swap {
        bool isPrivate;
        uint8 inTokenId;
        uint8 outTokenId;
        uint256 inTokenAmount;
        uint256 outTokenAmount;
        string l2Address;
        string l2SecretHash;
        bool isExecuted;
    }

    address public owner;
    ISwapRouter public immutable swapRouter;
    
    mapping(uint => Swap) public swaps;
    mapping(uint => address) public tokens;
    mapping(address => bool) public relayers;

    event SwapCreated(uint swapId, bool isPrivate, uint8 inTokenId, uint8 outTokenId, uint256 inTokenAmount, uint256 outTokenAmount, string l2Address, string l2SecretHash);
    event SwapExecuted(uint swapId, uint256 outTokenAmount);

    modifier onlyAdmin {
        require((relayers[msg.sender] == true) || msg.sender == owner, "You're not an admin!");
        _;
    }

    constructor(ISwapRouter _swapRouter, address relayer) {
        swapRouter = _swapRouter;
        owner = msg.sender;
        relayers[relayer] = true;
    }

    function addToken(uint l2TokenId, address l1TokenAddress) public onlyAdmin {
        tokens[l2TokenId] = l1TokenAddress;
    }

    function createSwap(uint swapId, bool isPrivate, uint8 inTokenId, uint8 outTokenId, uint256 inTokenAmount, string memory l2Address, string memory l2SecretHash) public onlyAdmin {
        require(swaps[swapId].inTokenAmount != 0, "Swap already exists!");

        swaps[swapId] = Swap(isPrivate, inTokenId, outTokenId, inTokenAmount, 0, l2Address, l2SecretHash, false);

        emit SwapCreated(swapId, isPrivate, inTokenId, outTokenId, inTokenAmount, 0, l2Address, l2SecretHash);
    }

    function executeSwap(uint swapId) public {
        address inToken = tokens[swaps[swapId].inTokenId];
        address outToken = tokens[swaps[swapId].outTokenId];

        require(inToken != address(0), "No address for input token!");
        require(outToken != address(0), "No address for output token!");

        TransferHelper.safeApprove(inToken, address(swapRouter), swaps[swapId].inTokenAmount);
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: inToken,
                tokenOut: outToken,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: swaps[swapId].inTokenAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        swaps[swapId].outTokenAmount = swapRouter.exactInputSingle(params);

        emit SwapExecuted(swapId, swaps[swapId].outTokenAmount);

        swaps[swapId].isExecuted = true;
    }

    function withdraw(address token) public onlyAdmin {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(this), balance);
        IERC20(token).transfer(msg.sender, balance);
    }
}
