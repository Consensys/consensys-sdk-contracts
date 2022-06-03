// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ERC721UserMintable.sol";

contract TestERC721UserMintable {
    ERC721UserMintable public instance;

    function beforeEach() public {
        instance = ERC721UserMintable(DeployedAddresses.ERC721UserMintable());
    }

    function testNameAndSymbolSetCorrectlyInConstructor() public {
        Assert.equal(instance.name(), "My Test Payable NFT", "name doesn't match");
        Assert.equal(instance.symbol(), "MTPNFT", "symbol doesn't match");
    }
}
