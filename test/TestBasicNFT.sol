// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/BasicNFT.sol";

contract TestBasicNFT {
    BasicNFT public basicNFT;

    function beforeEach() public {
        basicNFT = BasicNFT(DeployedAddresses.BasicNFT());
    }

    function testNameAndSymbolSetCorrectlyInConstructor() public {
        Assert.equal(basicNFT.name(), "My Test NFT", "name doesn't match");
        Assert.equal(basicNFT.symbol(), "MTNFT", "symbol doesn't match");
    }
}
