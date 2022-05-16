// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage, AccessControl, Ownable {
    using Counters for Counters.Counter;
    /// @dev Counter auto-incrementating NFT tokenIds, default: 0
    Counters.Counter private _tokenIdCounter;
    string private _contractURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Contract initiation:
    /// @notice The account deploying the contract will have the minter role and will be able to grand other accounts
    /// @notice The contract is built with only a name & a symbol as metadata. Each NFT metadata will be given at mint time
    constructor(string memory name_, string memory symbol_, string memory contractURI_) ERC721(name_, symbol_) {
        _contractURI = contractURI_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    /// @notice NFT minting with metadata i.e tokenURI
    /// @notice Each mint will increment the tokenId, starting from 0
    function mintWithTokenURI(address to_, string memory tokenURI_) public onlyRole(MINTER_ROLE) returns (bool) {
        require(bytes(tokenURI_).length > 1, "TokenURI cannot be empty");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        return true;
    }

    function burn(uint256 tokenId_) external {
        address owner = ERC721.ownerOf(tokenId_);
        require(owner == _msgSender(), "Only owner of token is allowed to burn");
        _burn(tokenId_);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(contractURI_).length > 1, "ContractURI cannot be empty");
        _contractURI = contractURI_;
    }

    // Overrides

    function supportsInterface(bytes4 interfaceId_) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }
}
