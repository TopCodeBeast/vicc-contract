// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./INextContract.sol";
import "./IViccCards.sol";
import "./IViccTokens.sol";
import "./MinterAccess.sol";
import "./RelayRecipient.sol";
import "./NFTClient.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ViccTokens is
    MinterAccess,
    RelayRecipient,
    ERC721("VICC", "VICC"),
    IViccTokens
{
    // Vicc cards
    IViccCards public viccCards;

    // Next contract
    INextContract public nextContract;

    constructor(address viccCardsAddress, address relayAddress)
        public
        RelayRecipient(relayAddress)
    {
        require(
            viccCardsAddress != address(0),
            "ViccCards address is required"
        );
        viccCards = IViccCards(viccCardsAddress);
    }

    /// @dev Set the prefix for the tokenURIs.
    function setTokenURIPrefix(string memory prefix) public onlyOwner {
        _setBaseURI(prefix);
    }

    /// @dev Set the potential next version contract
    function setNextContract(address nextContractAddress) public onlyOwner {
        require(
            address(nextContract) == address(0),
            "NextContract already set"
        );
        nextContract = INextContract(nextContractAddress);
    }

    /// @dev Creates a new card in the Cards contract and mints the token
    // prettier-ignore
    function createCardAndMintToken(
        uint256 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId,
        address to
    ) public onlyMinter override returns (uint256) {
        uint256 cardId = viccCards.createCard(
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        );

        _mint(to, cardId);
        return cardId;
    }

    /// @dev Mints a token for an existing card
    // prettier-ignore
    function mintToken(uint256 cardId, address to)
        public
        override
        onlyMinter
        returns (uint256)
    {
        require(viccCards.cardExists(cardId), "Card does not exist");

        _mint(to, cardId);
        return cardId;
    }

    /// @dev Migrates tokens to a potential new version of this contract
    /// @param tokenIds - list of tokens to transfer
    function migrateTokens(uint256[] calldata tokenIds) external {
        require(address(nextContract) != address(0), "Next contract not set");

        for (uint256 index = 0; index < tokenIds.length; index++) {
            transferFrom(_msgSender(), address(this), tokenIds[index]);
        }

        nextContract.migrateTokens(tokenIds, _msgSender());
    }

    /// @dev Pagination of owner tokens
    /// @param owner - address of the token owner
    /// @param page - page number
    /// @param rows - number of rows per page
    function tokensOfOwner(address owner, uint8 page, uint8 rows)
        public
        view
        returns (uint256[] memory)
    {
        return NFTClient.tokensOfOwner(address(this), owner, page, rows);
    }

    function getCard(uint256 tokenId)
        public
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
        (
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        ) = viccCards.getCard(tokenId);
    }

    function getPlayer(uint256 playerId)
        external
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        )
    {
        (name, yearOfBirth, monthOfBirth, dayOfBirth) = viccCards.getPlayer(
            playerId
        );
    }

    // prettier-ignore
    function getClub(uint16 clubId)
        external
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        )
    {
        (name, country, city, yearFounded) = viccCards.getClub(clubId);
    }

    // prettier-ignore
    function _msgSender() internal view override(RelayRecipient, Context) returns (address payable) {
        return RelayRecipient._msgSender();
    }

    // prettier-ignore
    function _msgData() internal view override(RelayRecipient, Context) returns (bytes memory) {
        return RelayRecipient._msgData();
    }
}
