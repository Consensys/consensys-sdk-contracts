const ERC721Mintable = artifacts.require("ERC721Mintable");
const {
    BN,           // Big Number support
    constants,    // Common constants, like the zero address and largest integers
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
  } = require('@openzeppelin/test-helpers');

contract("ERC721Mintable", async (accounts) => {
    const roleAdmin = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const roleMinter = '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6';
    let instance;

    beforeEach(async () => {
        instance = await ERC721Mintable.deployed();
    });

    // Instantiation

    it("should have owner be the deployer of the contract", async () => {
        const owner = await instance.owner();
        assert.equal(owner, accounts[0]);
    });

    it("should have the deployed name and symbol", async () => {
        const name = await instance.name.call();
        const symbol = await instance.symbol.call();
        assert.equal("My Test NFT", name);
        assert.equal("MTNFT", symbol);
    });

    // Mint

    it("should mint a new token", async () => {
        const tokenURIToStore = "ipfs://mysuperhash/0";
        const receipt = await instance.mintWithTokenURI(accounts[1], tokenURIToStore, { from: accounts[0] });

        const balanceOfAccount1 = await instance.balanceOf.call(accounts[1]);
        assert.equal(1, balanceOfAccount1.toString());

        const tokenURI = await instance.tokenURI.call(0);
        assert.equal(tokenURIToStore, tokenURI);

        expectEvent(receipt, 'Transfer', {
            from: constants.ZERO_ADDRESS,
            to: accounts[1],
            tokenId: new BN(0),
        });
    });

    it("should not let you mint with empty tokenURI", async () => {
        await expectRevert.unspecified(
            instance.mintWithTokenURI(accounts[1], "", { from: accounts[0] })
        );
    });

    it("should fail because account is not allowed to mint", async () => {
        try {
            await instance.mintWithTokenURI(accounts[1], "ipfs://mysuperhash/0", { from: accounts[1] });
        } catch (e) {
            assert.include(e.message, "is missing role");
        }
    });

    it("should return owner address", async () => {
        await instance.mintWithTokenURI(accounts[1], "ipfs://mysuperhash/0", { from: accounts[0] });

        const owner = await instance.ownerOf.call(0);
        assert.equal(accounts[1], owner);
    });

    it("should throw exception because token doesn't exist", async () => {
        try {
            await instance.ownerOf(1000);
        } catch (e) {
            assert.include(e.message, "ERC721: owner query for nonexistent token");
        }
    });

    // Roles

    it("should grant minter role to address", async () => {
        const hasRoleInitially = await instance.hasRole(roleMinter, accounts[1]);
        assert.equal(false, hasRoleInitially);

        await instance.grantRole(roleMinter, accounts[1], { from: accounts[0] });

        const hasRoleAfter = await instance.hasRole(roleMinter, accounts[1]);
        assert.equal(true, hasRoleAfter);
    });

    it("should fail because account cannot give minter role", async () => {
        try {
            await instance.grantRole(roleMinter, accounts[1], { from: accounts[1] });
        } catch (e) {
            assert.include(e.message, "is missing role");
        }
    });

    it("should renounce minter role by address[1]", async () => {
        const hasRoleInitially = await instance.hasRole(roleMinter, accounts[1]);
        assert.equal(true, hasRoleInitially);

        await instance.renounceRole(roleMinter, accounts[1], { from: accounts[1] });

        const hasRoleAfter = await instance.hasRole(roleMinter, accounts[1]);
        assert.equal(false, hasRoleAfter);
    });

    it("should renounce ownership", async () => {
        const receipt = await instance.renounceOwnership({ from: accounts[0] });
        expectEvent(receipt, 'OwnershipTransferred', {
            previousOwner: accounts[0],
            newOwner: constants.ZERO_ADDRESS,
        })
    });

    it("should fail to renounce ownership as caller is not the owner", async () => {
        await expectRevert(
            instance.renounceOwnership({ from: accounts[1] }),
            "Ownable: caller is not the owner"
        );
    });

    it("should revoke role from address", async () => {
        const hasRoleInitially = await instance.hasRole(roleMinter, accounts[2]);
        assert.equal(false, hasRoleInitially);

        const receipt = await instance.grantRole(roleMinter, accounts[2], { from: accounts[0] });
        expectEvent(receipt, 'RoleGranted', {
            role: roleMinter,
            account: accounts[2],
            sender: accounts[0],
        });

        const receiptTwo = await instance.revokeRole(roleMinter, accounts[2], { from: accounts[0] });
        expectEvent(receiptTwo, 'RoleRevoked', {
            role: roleMinter,
            account: accounts[2],
            sender: accounts[0],
        });
    });

    it("should revert as user cannot revoke role", async () => {
        try {
            await instance.revokeRole(roleMinter, accounts[2], { from: accounts[1] });
        } catch (e) {
            assert.include(e.message, "is missing role");
        }
    });

    // Approve

    it("should approve contract to other address", async () => {
        const approvedAddress = await instance.getApproved(0);
        
        if (approvedAddress !== '0x0000000000000000000000000000000000000000') {
            assert.fail("initial address is not zero address");
        }

        await instance.approve(accounts[2], 0, { from: accounts[1] });

        const approved = await instance.getApproved(0);
        assert.equal(accounts[2], approved);
    });

    it("should not let you approve to current owner", async () => {
        await expectRevert(
            instance.approve(accounts[1], 0, { from: accounts[1] }),
            "ERC721: approval to current owner",
          );
    });

    it("should not let you approve because sender is not the owner", async () => {
        await expectRevert(
            instance.approve(accounts[2], 0, { from: accounts[0] }),
            "ERC721: approve caller is not owner nor approved for all",
          );
    });

    // ContractURI

    it("should get the current contractURI", async () => {
        const uri = await instance.contractURI();
        assert.equal("", uri);
    });

    it("should set the current contractURI to something else", async () => {
        const newContractURI = "mymetadata.com";
        await instance.setContractURI(newContractURI, { from: accounts[0] });
        const uri = await instance.contractURI();
        assert.equal(newContractURI, uri);
    });

    it("should revert when setting contract URI to empty string", async function () {
        await expectRevert.unspecified(
            instance.setContractURI("", { from: accounts[0] })
        );
    });

    // SafeTransfer

    it("should let you safe transfer to new owner", async () => {
        const receipt = await instance.safeTransferFrom(accounts[1], accounts[2], 0, { from: accounts[1] });
        expectEvent(receipt, 'Transfer', {
            from: accounts[1],
            to: accounts[2],
            tokenId: new BN(0),
        });
    });

    it("should revert because address safeTransferring is not owner", async () => {
        await expectRevert(
            instance.safeTransferFrom(accounts[1], accounts[2], 0, { from: accounts[1] }),
            "ERC721: transfer caller is not owner nor approved"
        )
    });

    it("should revert because cannot safeTransfer to the zero address", async () => {
        await expectRevert(
            instance.safeTransferFrom(accounts[2], constants.ZERO_ADDRESS, 0, { from: accounts[2] }),
            "ERC721: transfer to the zero address"
        )
    });

    // Transfer

    it("should let you transfer to new owner", async () => {
        const receipt = await instance.transferFrom(accounts[2], accounts[1], 0, { from: accounts[2] });
        expectEvent(receipt, 'Transfer', {
            from: accounts[2],
            to: accounts[1],
            tokenId: new BN(0),
        });
    });

    it("should revert because address transferring is not owner", async () => {
        await expectRevert(
            instance.transferFrom(accounts[2], accounts[1], 0, { from: accounts[2] }),
            "ERC721: transfer caller is not owner nor approved"
        )
    });

    // setApprovalForAll

    it("should emit approval for all message", async () => {
        const receipt = await instance.setApprovalForAll(accounts[1], true, { from: accounts[2] });

        expectEvent(receipt, 'ApprovalForAll', {
            owner: accounts[2],
            operator: accounts[1],
            approved: true
        });
    });

    it("should revert as owner is caller", async () => {
        await expectRevert(
            instance.setApprovalForAll(accounts[1], true, { from: accounts[1] }),
            "ERC721: approve to caller"
        )
    });

    // Royalties

    it("should have no royalties initially", async () => {
        const response = await instance.royaltyInfo(0, 100);
        assert.equal(constants.ZERO_ADDRESS, response[0]);
        assert.equal(0, response[1].toNumber());
    });

    it("should set royalties", async () => {
        await instance.setRoyalties(accounts[0], 250, { from: accounts[0] });

        const response = await instance.royaltyInfo(0, 10000);
        assert.equal(accounts[0], response[0]);
        assert.equal(250, response[1].toNumber());
    });

    it("should revert as setting receiver to zero address", async () => {
        await expectRevert(
            instance.setRoyalties(constants.ZERO_ADDRESS, 100),
            "ERC2981: invalid receiver"
        )
    });

    it("should revert as royalties are too high", async () => {
        await expectRevert(
            instance.setRoyalties(constants.ZERO_ADDRESS, 10001, { from: accounts[0] }),
            "ERC2981: royalty fee will exceed salePrice"
        )
    });

    it("should revert as caller is not admin", async () => {
        try {
            await instance.setRoyalties(constants.ZERO_ADDRESS, 100, { from: accounts[1] });
        } catch (e) {
            assert.include(e.message, "is missing role");
        }
    });

    // View Methods

    it("should return correct balanceOf", async () => {
        const response = await instance.balanceOf(accounts[1]);
        assert.equal(2, response.toNumber());
    });

    it("should return the DEFAULT_ADMIN bytes code", async () => {
        const response = await instance.DEFAULT_ADMIN_ROLE();
        assert.equal(roleAdmin, response);
    });

    it("should get role admin for minter role", async () => {
        const response = await instance.getRoleAdmin(roleMinter);
        assert.equal(roleAdmin, response);
    });

    it("should return true as is approved for all", async () => {
        const response = await instance.isApprovedForAll(accounts[2], accounts[1]);
        assert.equal(true, response);
    });
});