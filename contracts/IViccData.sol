// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IViccData {
    function createPlayer(
        string calldata name,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    ) external returns (uint256);

    function getPlayer(uint256 playerId)
        external
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        );

    function createClub(
        string calldata name,
        string calldata country,
        string calldata city,
        uint16 yearFounded
    ) external returns (uint16);

    function getClub(uint16 clubId)
        external
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        );

    function playerExists(uint256 playerId) external view returns (bool);

    function clubExists(uint16 clubId) external view returns (bool);
}