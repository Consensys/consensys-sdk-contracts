// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721UserMintable is ERC721URIStorage, ERC2981, Ownable {
    using Counters for Counters.Counter;
    /// @dev Counter auto-incrementating NFT tokenIds, default: 0
    Counters.Counter private _tokenIdsCounter;

    uint256 private _maxSupply;
    string private _baseURI;
    uint256 private _price;
    bool private _isRevealed;
    bool private _saleStatus;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, uint256 maxSupply_, uint256 price_) ERC721(name_, symbol_) {
        _baseURI = baseURI_;
        _maxSupply = maxSupply_;
        _price = price_;
    }

    function toggleSale() external onlyOwner {

    }

    function setContractURI() external onlyOwner {

    }

    function setPrice() external onlyOwner {

    }

    function mint() public payable {

    }

    function setRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function withdraw() public onlyOwner {

    }
}
