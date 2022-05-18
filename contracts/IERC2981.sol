// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC2981 {

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId_ - the NFT asset queried for royalty information
    /// @param salePrice_ - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice_
    function royaltyInfo(
        uint256 tokenId_,
        uint256 salePrice_
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}
