var BasicNFT = artifacts.require("./BasicNFT.sol");

module.exports = function(deployer) {
  deployer.deploy(BasicNFT, "My Test NFT", "MTNFT");
};
