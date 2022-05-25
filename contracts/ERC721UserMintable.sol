// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// Name of contract cannot be empty.
error NameIsEmpty();
/// Base URI of tokens to be minted cannot be empty.
error BaseURIIsEmpty();

contract ERC721UserMintable is ERC721, ERC2981, Ownable {
    using Address for address;
    using Counters for Counters.Counter;
    /// @dev Counter auto-incrementating NFT tokenIds, default: 0
    Counters.Counter private _tokenIdCounter;

    uint256 private _maxSupply;
    string private _tokenBaseURI;
    uint256 private _price;
    bool private _isRevealed;
    bool private _saleIsActive;

    event ContractDeployed(address contractAddress_);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxSupply_,
        uint256 price_
    ) ERC721(name_, symbol_) {
        if (!(bytes(name_).length > 1)) {
            revert NameIsEmpty();
        }
        _tokenBaseURI = baseURI_;
        _maxSupply = maxSupply_;
        _price = price_;

        emit ContractDeployed(address(this));
    }

    function mint() public payable {
        require(_saleIsActive, "Mint is not active at this time.");
        require(
            msg.value >= _price,
            "Need to send at least amount of mint price"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function reveal(string memory baseURI_) external onlyOwner {
        require(!_isRevealed, "URI has already been revealed");
        _tokenBaseURI = baseURI_;
        _isRevealed = true;
    }

    function toggleSale() external onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        if (!(bytes(baseURI_).length > 1)) {
            revert BaseURIIsEmpty();
        }
        _tokenBaseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        _price = price_;
    }

    function setRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _tokenBaseURI;
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }
}
