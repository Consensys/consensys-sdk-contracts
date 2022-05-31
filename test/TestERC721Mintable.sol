// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ERC721Mintable.sol";

contract TestERC721Mintable {
    ERC721Mintable public instance;

    function beforeEach() public {
        instance = ERC721Mintable(DeployedAddresses.ERC721Mintable());
    }

    function testNameAndSymbolSetCorrectlyInConstructor() public {
        Assert.equal(instance.name(), "My Test NFT", "name doesn't match");
        Assert.equal(instance.symbol(), "MTNFT", "symbol doesn't match");
    }
}
