var ERC721Mintable = artifacts.require("ERC721Mintable");
var ERC721UserMintable = artifacts.require("ERC721UserMintable");

module.exports = function(deployer) {
  // deployer.deploy(ERC721Mintable, "My Test NFT", "MTNFT", "");
  deployer.deploy(ERC721UserMintable, "My Test Payable NFT", "MTPNFT", "", 2, 10000000000, "");
};
