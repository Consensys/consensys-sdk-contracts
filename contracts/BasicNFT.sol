// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage, AccessControl, Pausable, Ownable {
    using Counters for Counters.Counter;
    /// @dev Counter auto-incrementating NFT tokenIds, default: 0
    Counters.Counter private _tokenIdCounter;
    string private _contractMetadataURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Contract initiation:
    /// @notice The account deploying the contract will have the minter role and will be able to grand other accounts
    /// @notice The contract is built with only a name & a symbol as metadata. Each NFT metadata will be given at mint time
    constructor(string memory name_, string memory symbol_, string memory contractMetadataURI_) ERC721(name_, symbol_) {
        _contractMetadataURI = contractMetadataURI_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice NFT minting with metadata i.e tokenURI
    /// @notice Each mint will increment the tokenId, starting from 0
    function mintWithTokenURI(address to_, string memory metadataURI_) public onlyRole(MINTER_ROLE) returns (bool) {
        require(bytes(metadataURI_).length > 1, "MetadataURI cannot be empty");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, metadataURI_);
        return true;
    }

    function burn(uint256 tokenId_) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(tokenId_);
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    function setContractURI(string memory contractURI_) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(bytes(contractURI_).length > 1, "ContractURI cannot be empty");
        _contractMetadataURI = contractURI_;
    }

    // Overrides: add whenNotPaused modifier

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function approve(address to_, uint256 tokenId_) public whenNotPaused override {
        super.approve(to_, tokenId_);
    }

    function grantRole(bytes32 role_, address account_) public whenNotPaused override onlyRole(getRoleAdmin(role_)) {
        super.grantRole(role_, account_);
    }

    function revokeRole(bytes32 role_, address account_) public whenNotPaused override onlyRole(getRoleAdmin(role_)) {
        super.revokeRole(role_, account_);
    }

    function renounceRole(bytes32 role_, address account_) public whenNotPaused override {
        super.renounceRole(role_, account_);
    }

    function renounceOwnership() public whenNotPaused onlyOwner override {
        super.renounceOwnership();
    }

    function transferOwnership(address newOwner_) public whenNotPaused onlyOwner override {
        super.transferOwnership(newOwner_);
    }

    function setApprovalForAll(address operator_, bool approved_) public whenNotPaused override {
        super.setApprovalForAll(operator_, approved_);
    }

    function supportsInterface(bytes4 interfaceId_) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }
}
