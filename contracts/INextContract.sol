// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface INextContract {
    function migrateTokens(uint256[] calldata tokenIds, address to) external;
}
