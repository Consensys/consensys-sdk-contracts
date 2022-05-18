// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './IERC2981.sol';

/// @dev This contract is used to add ERC2981 support to NFT contracts
abstract contract ERC2981Base is ERC165, IERC2981 {
    struct RoyaltyInfo {
        address _recipient;
        uint24 _amount;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId_ == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}
