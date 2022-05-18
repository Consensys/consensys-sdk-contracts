// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './ERC2981Base.sol';

error RoyaltiesTooHigh(uint256 passed, uint256 max);

/// @dev This is a contract used to add ERC2981 support to ERC721 and ERC1155 contracts
/// @dev This implementation has the same royalties contract wide
abstract contract ERC2981ContractRoyalties is ERC2981Base {
    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param recipient_ recipient of the royalties
    /// @param value_ basis points (using 2 decimals -> 10000 value_ = 100%, 0 = 0%)
    function _setRoyalties(address recipient_, uint256 value_) internal {
        if (value_ > 10000) {
            revert RoyaltiesTooHigh({
                passed: value_,
                max: 10000
            });
        }
        _royalties = RoyaltyInfo(recipient_, uint24(value_));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value_)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value_ * royalties.amount) / 10000;
    }
}
