// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./IViccCards.sol";
import "./IViccData.sol";
import "./MinterAccess.sol";
import "./CapperAccess.sol";

contract ViccCards is MinterAccess, CapperAccess, IViccCards {
    struct Card {
        // The id of the football Player
        uint256 playerId;
        /// @dev Contains the immutable metadata hash for each card.The IPFS address can be computed
        /// like so base58('1220' + hex(value))
        bytes32 metadata;
        // The football season represented by the first year of the season: Season 2018/2019 is 2018.
        uint16 season;
        // Card serial number
        uint16 serialNumber;
        // Card scarcity
        uint8 scarcity;
        // Id of the football club
        uint16 clubId;
    }

    /// @dev The CardAdded is fired whenever a new Card is minted.
    event CardAdded(
        uint256 indexed cardId,
        uint256 indexed playerId,
        uint16 indexed season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    );

    IViccData private viccData;

    /// @dev The limit number of cards that can be minted depending on their Scarcity Level.
    uint256[] public scarcityLimitByLevel;

    /// @dev Specifies if production of cards of a given season and scarcity has been stopped
    mapping(uint16 => mapping(uint256 => bool)) internal stoppedProductionBySeasonAndScarcityLevel;

    /// @dev A mapping containing the Card struct for all Cards in existence.
    mapping(uint256 => Card) public cards;

    constructor(address viccDataAddress) public {
        require(
            viccDataAddress != address(0),
            "ViccData address is required"
        );
        viccData = IViccData(viccDataAddress);

        scarcityLimitByLevel.push(1);
        scarcityLimitByLevel.push(10);
        scarcityLimitByLevel.push(100);
    }

    /// @dev Init the maximum number of cards that can be created for a scarcity level.
    function setScarcityLimit(uint256 limit) public onlyCapper {
        uint256 editedScarcities = scarcityLimitByLevel.length - 1;
        require(
            limit >= scarcityLimitByLevel[editedScarcities] * 2,
            "Limit not large enough"
        );

        scarcityLimitByLevel.push(limit);
    }

    /// @dev Stop the production of cards for a given season and scarcity level
    function stopProductionForSeasonAndScarcityLevel(uint16 season, uint8 level)
        public
        onlyMinter
    {
        stoppedProductionBySeasonAndScarcityLevel[season][level] = true;
    }

    /// @dev Returns true if the production has been stopped for a given season and scarcity level
    function productionStoppedForSeasonAndScarcityLevel(
        uint16 season,
        uint8 level
    ) public view returns (bool) {
        return stoppedProductionBySeasonAndScarcityLevel[season][level];
    }

    // prettier-ignore
    function createCard(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    )
        public
        onlyMinter
        override
        returns (
            uint256
        )
    {
        require(viccData.playerExists(playerId), "Player does not exist");
        require(viccData.clubExists(clubId), "Club does not exist");

        require(
            serialNumber >= 1 && serialNumber <= scarcityLimitByLevel[scarcity],
            "Invalid serial number"
        );
        require(
            stoppedProductionBySeasonAndScarcityLevel[season][scarcity] ==
                false,
            "Production has been stopped"
        );

        Card memory card;
        card.playerId = playerId;
        card.season = season;
        card.scarcity = scarcity;
        card.serialNumber = serialNumber;
        card.metadata = metadata;
        card.clubId = clubId;
        uint256 cardId = uint256(
            keccak256(
                abi.encodePacked(
                    playerId,
                    season,
                    uint256(scarcity),
                    serialNumber
                )
            )
        );

        require(cards[cardId].playerId == 0, "Card already exists");

        cards[cardId] = card;

        emit CardAdded(
            cardId,
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        );

        return cardId;
    }

    // prettier-ignore
    function getCard(
        uint256 cardId // prettier-ignore
    )
        external
        override
        view
        returns (
            uint256 playerId,
            uint16 season,
            uint256 scarcity,
            uint16 serialNumber,
            bytes memory metadata,
            uint16 clubId
        )
    {
        Card storage c = cards[cardId];
        playerId = c.playerId;
        season = c.season;
        scarcity = c.scarcity;
        serialNumber = c.serialNumber;
        // Our IPFS hash will always be encoded using SHA256
        metadata = sha256Bytes32ToBytes(c.metadata);
        clubId = c.clubId;
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
        (name, yearOfBirth, monthOfBirth, dayOfBirth) = viccData.getPlayer(playerId);
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
        (name, country, city, yearFounded) = viccData.getClub(clubId);
    }

    // prettier-ignore
    function cardExists(uint256 cardId) external override view returns(bool) {
        Card storage card = cards[cardId];
        return card.season > 0;
    }

    function sha256Bytes32ToBytes(bytes32 _bytes32)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory bytesArray = new bytes(34);
        bytesArray[0] = 0x12;
        bytesArray[1] = 0x20;
        // We add 0x1220 to specify the encryption algorithm
        for (uint256 i = 2; i < 34; i++) {
            bytesArray[i] = _bytes32[i - 2];
        }
        return bytesArray;
    }
}
