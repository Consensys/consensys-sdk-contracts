var NFTContractUnlimited = artifacts.require("NFTContractUnlimited");

module.exports = function(deployer) {
  deployer.deploy(NFTContractUnlimited, "My Test NFT", "MTNFT", "");
};
