// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NFT.sol";

contract TestBasicNFT {
    NFT public basicNFT;

    function beforeEach() public {
        basicNFT = NFT(DeployedAddresses.NFT());
    }

    function testNameAndSymbolSetCorrectlyInConstructor() public {
        Assert.equal(basicNFT.name(), "My Test NFT", "name doesn't match");
        Assert.equal(basicNFT.symbol(), "MTNFT", "symbol doesn't match");
    }
}
