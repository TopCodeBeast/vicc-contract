// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

library NFTClient {
    bytes4 public constant interfaceIdERC721 = 0x80ac58cd;

    function requireERC721(address _candidate) public view {
        require(
            IERC721Enumerable(_candidate).supportsInterface(interfaceIdERC721),
            "IS_NOT_721_TOKEN"
        );
    }

    function transferTokens(
        IERC721Enumerable _nftContract,
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            if (_tokenIds[index] == 0) {
                break;
            }

            _nftContract.safeTransferFrom(_from, _to, _tokenIds[index]);
        }
    }

    function transferAll(
        IERC721Enumerable _nftContract,
        address _sender,
        address _receiver
    ) public {
        uint256 balance = _nftContract.balanceOf(_sender);
        while (balance > 0) {
            _nftContract.safeTransferFrom(
                _sender,
                _receiver,
                _nftContract.tokenOfOwnerByIndex(_sender, balance - 1)
            );
            balance--;
        }
    }

    // /// @dev Pagination of owner tokens
    // /// @param owner - address of the token owner
    // /// @param page - page number
    // /// @param rows - number of rows per page
    function tokensOfOwner(
        address _nftContract,
        address owner,
        uint8 page,
        uint8 rows
    ) public view returns (uint256[] memory) {
        requireERC721(_nftContract);

        IERC721Enumerable nftContract = IERC721Enumerable(_nftContract);

        uint256 tokenCount = nftContract.balanceOf(owner);
        uint256 offset = page * rows;
        uint256 range = offset > tokenCount
            ? 0
            : min(tokenCount - offset, rows);
        uint256[] memory tokens = new uint256[](range);
        for (uint256 index = 0; index < range; index++) {
            tokens[index] = nftContract.tokenOfOwnerByIndex(
                owner,
                offset + index
            );
        }
        return tokens;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }
}
