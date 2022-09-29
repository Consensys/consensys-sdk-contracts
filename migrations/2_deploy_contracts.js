var ERC721Mintable = artifacts.require("ERC721Mintable");
var ERC721UserMintable = artifacts.require("ERC721UserMintable");
var ERC1155Mintable = artifacts.require("ERC1155Mintable");

module.exports = function(deployer) {
  // deployer.deploy(ERC721Mintable, "My Test NFT", "MTNFT", "");
  // deployer.deploy(ERC721UserMintable, "My Test Payable NFT", "MTPNFT", "", "", 10, 10000000000, 3);
  deployer.deploy(ERC1155Mintable, "mymetadata.com/", "mycontracturi.com", [0, 1, 2]);

};
