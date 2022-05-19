var ERC721Mintable = artifacts.require("ERC721Mintable");

module.exports = function(deployer) {
  deployer.deploy(ERC721Mintable, "My Test NFT", "MTNFT", "");
};
