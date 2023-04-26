// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./IViccData.sol";
import "./MinterAccess.sol";

contract ViccData is IViccData, MinterAccess {
    struct Player {
        // The name of the actual football player
        string name;
        // The year of birth of the actual football player.
        uint16 yearOfBirth;
        // The month of birth of the actual football player.
        // January is 1.
        uint8 monthOfBirth;
        // The day of birth of the actual football player.
        uint8 dayOfBirth;
    }

    struct Club {
        // Name of the club, leave blank for national team
        string name;
        // Country of the club or national team
        string country;
        // City of the club, leave blank for national team
        string city;
        // Year founded of the club, leave blank for national team
        uint16 yearFounded;
    }

    /// @dev PlayerAdded is fired whenever a new player is added.
    event PlayerAdded(
        uint256 indexed playerId,
        string playerName,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    );

    event ClubAdded(
        uint16 indexed clubId,
        string name,
        string country,
        string city,
        uint16 yearFounded
    );

    /// @dev A mapping containing the Player struct for all Players in existence.
    mapping(uint256 => Player) public players;

    /// @dev A mapping of club hashes to club id
    mapping(uint256 => uint16) public clubIds;

    /// @dev An array containing all the Clubs
    Club[] public clubs;

    /// @dev Creates a new Player.
    // prettier-ignore
    function createPlayer(
        string calldata name,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    ) external onlyMinter override returns (uint256) {
        require(
            monthOfBirth >= 1 &&
                monthOfBirth <= 12 &&
                dayOfBirth >= 1 &&
                dayOfBirth <= 31,
            "Invalid birth date"
        );

        uint256 playerId = uint256(
            keccak256(
                abi.encodePacked(name, yearOfBirth, monthOfBirth, dayOfBirth)
            )
        );

        require(players[playerId].dayOfBirth == 0, "Player already exists");

        Player memory player = Player({
            name: name,
            dayOfBirth: dayOfBirth,
            monthOfBirth: monthOfBirth,
            yearOfBirth: yearOfBirth
        });

        players[playerId] = player;

        emit PlayerAdded(playerId, name, yearOfBirth, monthOfBirth, dayOfBirth);

        return playerId;
    }

    //prettier-ignore
    function createClub(
        string calldata name,
        string calldata country,
        string calldata city,
        uint16 yearFounded
    ) external override onlyMinter returns (uint16) {
        require(bytes(country).length > 0, "Country is required");
        require(clubs.length < 65535, "Too many clubs");

        uint256 clubHash = uint256(
            keccak256(abi.encodePacked(name, country, city, yearFounded))
        );

        require(clubIds[clubHash] == 0, "Club already exists");

        Club memory club = Club({
            name: name,
            country: country,
            city: city,
            yearFounded: yearFounded
        });

        clubs.push(club);
        uint16 clubId = uint16(clubs.length);
        clubIds[clubHash] = clubId;

        emit ClubAdded(clubId, name, country, city, yearFounded);

        return clubId;
    }

    // prettier-ignore
    function getPlayer(uint256 playerId)
        external
        override
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        )
    {
        Player storage p = players[playerId];
        name = p.name;
        yearOfBirth = p.yearOfBirth;
        monthOfBirth = p.monthOfBirth;
        dayOfBirth = p.dayOfBirth;
    }

    // prettier-ignore
    function getClub(uint16 clubId)
        external
        override
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        )
    {
        Club storage c = clubs[clubId - 1];
        name = c.name;
        country = c.country;
        city = c.city;
        yearFounded = c.yearFounded;
    }

    // prettier-ignore
    function playerExists(uint256 playerId) external override view returns(bool) {
        Player storage player = players[playerId];
        return player.yearOfBirth > 0;
    }

    // prettier-ignore
    function clubExists(uint16 clubId) external override view returns (bool) {
        return clubId <= clubs.length;
    }
}