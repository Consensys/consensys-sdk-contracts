// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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
/// Max supply is less than max
/// @param maxSupply maximum number of tokens that will ever be available for this collection
/// @param maxTokenRequest maximum number of tokens that can be minted at any one time
error InvalidMaxSupply(uint256 maxSupply, uint8 maxTokenRequest);

contract ERC721UserMintable is
    ERC721,
    ERC2981,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    using Address for address;
    using Counters for Counters.Counter;
    /// @dev Counter auto-incrementating NFT tokenIds, default: 0
    Counters.Counter private _tokenIdCounter;

    bool private _isRevealed;
    bool private _saleIsActive;
    uint8 private _maxTokenRequest;
    uint256 private immutable _maxSupply;
    uint256 private _price;
    string private _tokenBaseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxSupply_,
        uint256 price_,
        uint8 maxTokenRequest_
    ) ERC721(name_, symbol_) {
        if (!(bytes(name_).length > 1)) {
            revert NameIsEmpty();
        }
        if (maxSupply_ < maxTokenRequest_) {
            revert InvalidMaxSupply({
                maxSupply: maxSupply_,
                maxTokenRequest: maxTokenRequest_
            });
        }
        _tokenBaseURI = baseURI_;
        _maxSupply = maxSupply_;
        _maxTokenRequest = maxTokenRequest_;
        _price = price_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///#if_succeeds quantity_ <= old(maxTokenRequest());
    ///#if_succeeds totalSupply() <= old(maxSupply());
    ///#if_succeeds old(totalSupply()) + quantity_ == totalSupply();
    function reserve(uint256 quantity_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
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
            _safeMint(msg.sender, tokenId);
        }
    }

    ///#if_succeeds old(_saleIsActive);
    ///#if_succeeds quantity_ <= old(maxTokenRequest());
    ///#if_succeeds totalSupply() <= old(maxSupply());
    ///#if_succeeds msg.value >= old(price()) * quantity_;
    ///#if_succeeds old(totalSupply()) + quantity_ == totalSupply();
    function mint(uint256 quantity_) public payable nonReentrant {
        require(_saleIsActive, "Sale is not active at this time");
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
        uint256 totalCost = price() * quantity_;
        if (msg.value < totalCost) {
            revert InsufficientFunds({
                sent: msg.value,
                required: price() * quantity_
            });
        }
        for (uint256 i = 0; i < quantity_; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
        if (msg.value > totalCost) {
            uint256 toRefund = msg.value - totalCost;
            msg.sender.call{value: toRefund}("");
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

    function maxTokenRequest() public view returns (uint8) {
        return _maxTokenRequest;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    ///#if_succeeds old(_isRevealed) == false;
    ///#if_succeeds _isRevealed == true;
    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) != keccak256(abi.encodePacked((""))));
    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) == keccak256(abi.encodePacked((baseURI_))));
    function reveal(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!_isRevealed, "URI has already been revealed");
        if (!(bytes(baseURI_).length > 1)) {
            revert BaseURIIsEmpty();
        }
        _tokenBaseURI = baseURI_;
        _isRevealed = true;
    }

    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) != keccak256(abi.encodePacked((""))));
    ///#if_succeeds (keccak256(abi.encodePacked((_tokenBaseURI))) == keccak256(abi.encodePacked((baseURI_))));
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!(bytes(baseURI_).length > 1)) {
            revert BaseURIIsEmpty();
        }
        _tokenBaseURI = baseURI_;
    }

    ///#if_succeeds _maxTokenRequest == maxTokenRequest_;
    function setMaxTokenRequest(uint8 maxTokenRequest_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _maxTokenRequest = maxTokenRequest_;
    }

    ///#if_succeeds _price == price_;
    function setPrice(uint256 price_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = price_;
    }

    ///#if_succeeds let receiver, _ := royaltyInfo(0, 10000) in receiver == receiver_;
    function setRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    ///#if_succeeds old(_saleIsActive) == !_saleIsActive;
    function toggleSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _saleIsActive = !_saleIsActive;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    ///#if_succeeds address(this).balance == 0;
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _tokenBaseURI;
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC721, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }
}
