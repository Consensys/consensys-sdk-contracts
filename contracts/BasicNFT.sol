// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract BasicNFT is ERC721URIStorage, AccessControl, Ownable {
    using Counters for Counters.Counter;
    /// @dev Counter auto-incrementating NFT tokenIds, default: 0
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Contract initiation:
    /// @notice The account deploying the contract will have the minter role and will be able to grand other accounts
    /// @notice The contract is built with only a name & a symbol as metadata. Each NFT metadata will be given at mint time
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    /// @notice NFT minting with metadata i.e tokenURI
    /// @notice Each mint will increment the tokenId, starting from 0
    function mintWithTokenURI(address to, string memory metadataURI) public onlyRole(MINTER_ROLE) returns (bool) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);
        return true;
    }

    function addMinter(address minter) public onlyRole(MINTER_ROLE) {
        _grantRole(MINTER_ROLE, minter);
    }

    function addBurner(address burner) public onlyRole(BURNER_ROLE) {
        _grantRole(BURNER_ROLE, burner);
    }

    function renounceMinter() public onlyRole(MINTER_ROLE) {
        _revokeRole(MINTER_ROLE, msg.sender);
    }

    function renounceBurner() public onlyRole(BURNER_ROLE) {
        _revokeRole(BURNER_ROLE, msg.sender);
    }

    function burn(uint256 _tokenId) external onlyRole(BURNER_ROLE) {
        _burn(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
