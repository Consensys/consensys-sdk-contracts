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
/// Too many tokens requested: `quantity` requested but maximum allowed is `maxTokenPurchase`.
/// @param quantity requested amount.
/// @param maxTokenPurchase maximum amount available per transaction.
error MaxTokenRequestExceeded(uint256 quantity, uint256 maxTokenPurchase);
/// Request would exceed max supply: `quantity` requested but maximum allowed is `maxSupply`.
/// @param quantity requested amount.
/// @param maxSupply maximum amount available.
error MaxSupplyExceeded(uint256 quantity, uint256 maxSupply);
/// Insufficient funds sent: `sent` ether but `required` is required.
/// @param sent total ether sent with transaction.
/// @param required total ether required to purchase.
error InsufficientFunds(uint256 sent, uint256 required);
/// Sale is not active at this time.
error InactiveSale();

contract ERC721UserMintable is ERC721, ERC2981, Ownable {
    using Address for address;
    using Counters for Counters.Counter;
    /// @dev Counter auto-incrementating NFT tokenIds, default: 0
    Counters.Counter private _tokenIdCounter;

    bool private _isRevealed;
    bool private _saleIsActive;
    uint8 private constant MAX_TOKEN_REQUEST = 20;
    uint256 private _maxSupply;
    uint256 private _price;
    string private _tokenBaseURI;

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

    ///#if_succeeds quantity_ <= old(maxTokenRequest());
    ///#if_succeeds totalSupply() <= old(maxSupply());
    ///#if_succeeds old(totalSupply()) + quantity_ == totalSupply();
    function reserve(uint256 quantity_) external onlyOwner {
        if (quantity_ > maxTokenRequest()) {
            revert MaxTokenRequestExceeded({
                quantity: quantity_,
                maxTokenPurchase: maxTokenRequest()
            });
        }
        if (totalSupply() + quantity_ > maxSupply()) {
            revert MaxSupplyExceeded({
                quantity: quantity_,
                maxSupply: maxSupply()
            });
        }

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint(_msgSender(), tokenId);
        }
    }

    ///#if_succeeds old(_saleIsActive);
    ///#if_succeeds quantity_ <= old(maxTokenRequest());
    ///#if_succeeds totalSupply() <= old(maxSupply());
    ///#if_succeeds msg.value >= old(price()) * quantity_;
    ///#if_succeeds old(totalSupply()) + quantity_ == totalSupply();
    function mint(uint256 quantity_) public payable {
        if (!_saleIsActive) {
            revert InactiveSale();
        }
        if (quantity_ > maxTokenRequest()) {
            revert MaxTokenRequestExceeded({
                quantity: quantity_,
                maxTokenPurchase: maxTokenRequest()
            });
        }
        if (totalSupply() + quantity_ > maxSupply()) {
            revert MaxSupplyExceeded({
                quantity: quantity_,
                maxSupply: maxSupply()
            });
        }
        if (msg.value < price() * quantity_) {
            revert InsufficientFunds({
                sent: msg.value,
                required: price() * quantity_
            });
        }
        for (uint256 i = 0; i < quantity_; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint(_msgSender(), tokenId);
        }
    }

    function contractURI() public view returns (string memory) {
        return _tokenBaseURI;
    }

    function isSaleActive() public view returns (bool) {
        return _saleIsActive;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function maxTokenRequest() public pure returns (uint8) {
        return MAX_TOKEN_REQUEST;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    ///#if_succeeds old(_isRevealed) == false;
    ///#if_succeeds _isRevealed == true;
    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) != keccak256(abi.encodePacked((""))));
    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) == keccak256(abi.encodePacked((baseURI_))));
    function reveal(string memory baseURI_) external onlyOwner {
        require(!_isRevealed, "URI has already been revealed");
        if (!(bytes(baseURI_).length > 1)) {
            revert BaseURIIsEmpty();
        }
        _tokenBaseURI = baseURI_;
        _isRevealed = true;
    }

    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) != keccak256(abi.encodePacked((""))));
    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) == keccak256(abi.encodePacked((baseURI_))));
    function setBaseURI(string memory baseURI_) external onlyOwner {
        if (!(bytes(baseURI_).length > 1)) {
            revert BaseURIIsEmpty();
        }
        _tokenBaseURI = baseURI_;
    }

    ///#if_succeeds _price == price_;
    function setPrice(uint256 price_) external onlyOwner {
        _price = price_;
    }

    ///#if_succeeds let receiver, _ := royaltyInfo(0, 10000) in receiver == receiver_;
    function setRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    ///#if_succeeds old(_saleIsActive) == !_saleIsActive;
    function toggleSale() external onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    ///#if_succeeds address(this).balance == 0;
    function withdraw() external onlyOwner {
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
