// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IViccTokens {
    function createCardAndMintToken(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId,
        address to
    ) external returns (uint256);

    function mintToken(uint256 cardId, address to) external returns (uint256);
}
