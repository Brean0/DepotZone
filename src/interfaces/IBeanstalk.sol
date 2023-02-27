// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";

enum From {
    EXTERNAL,
    INTERNAL,
    EXTERNAL_INTERNAL,
    INTERNAL_TOLERANT
}
enum To {
    EXTERNAL,
    INTERNAL
}

interface IBeanstalk {
    function transferInternalTokenFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount,
        To toMode
    ) external payable;

    function permitToken(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function transferDeposit(
        address sender,
        address recipient,
        address token,
        uint32 season,
        uint256 amount
    ) external payable returns (uint256 bdv);

    function transferDeposits(
        address sender,
        address recipient,
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) external payable returns (uint256[] memory bdvs);

    function permitDeposits(
        address owner,
        address spender,
        address[] calldata tokens,
        uint256[] calldata values,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function permitDeposit(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function balanceOfEarnedBeans(address account) external view returns (uint256);

    function update(address account) external payable;

    function balanceOfGrownStalk(address account) external view returns (uint256);
}
