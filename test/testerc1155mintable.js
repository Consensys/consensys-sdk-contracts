const ERC1155Mintable = artifacts.require("ERC1155Mintable");
const {
    BN,           // Big Number support
    constants,    // Common constants, like the zero address and largest integers
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
  } = require('@openzeppelin/test-helpers');

contract("ERC1155Mintable", async (accounts) => {
    const roleAdmin = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const roleMinter = '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6';
    let instance;

    beforeEach(async () => {
        instance = await ERC1155Mintable.deployed();
    });

    // Instantiation

    it("should have owner be the deployer of the contract", async () => {
        const owner = await instance.owner();
        assert.equal(owner, accounts[0]);
    });

    // Mint

    it("should mint a new token", async () => {
        const idToMint = 0;
        const expectedURI = "mymetadata.com/0.json";
        const receipt = await instance.mint(accounts[1], idToMint, 1);

        const balanceOfAccount1 = await instance.balanceOf.call(accounts[1], idToMint);
        assert.equal(1, balanceOfAccount1.toString());

        const tokenURI = await instance.uri.call(0);
        assert.equal(expectedURI, tokenURI);

        expectEvent(receipt, 'TransferSingle', {
            operator: accounts[0],
            from: constants.ZERO_ADDRESS,
            to: accounts[1],
            id: new BN(0),
            value: new BN(1),
        });
    });

    it("should fail because account is not allowed to mint", async () => {
        try {
            await instance.mint(accounts[1], 0, 1, { from: accounts[1] });
        } catch (e) {
            assert.include(e.message, "is missing role");
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

    // baseURI

    it("should set the current baseURI to something else", async () => {
        const newContractURI = "myupdated_metadata.com/";
        await instance.setURI(newContractURI, { from: accounts[0] });
        const uri = await instance.uri(0);
        assert.equal(newContractURI + "0.json", uri);
    });

    it("should revert when setting contract URI to empty string", async function () {
        await expectRevert.unspecified(
            instance.setURI("", { from: accounts[0] })
        );
    });

    // SafeTransfer

    it("should let you safe transfer to new owner", async () => {
        const receipt = await instance.safeTransferFrom(accounts[1], accounts[2], 0, 1, [], { from: accounts[1] });
        expectEvent(receipt, 'TransferSingle', {
            operator: accounts[1],
            from: accounts[1],
            to: accounts[2],
            id: new BN(0),
            value: new BN(1),
        });
    });

    it("should revert because address safeTransferring is not owner", async () => {
        await expectRevert(
            instance.safeTransferFrom(accounts[2], accounts[1], 0, 1, [], { from: accounts[0] }),
            "ERC1155: caller is not owner nor approved"
        )
    });

    it("should revert because cannot safeTransfer to the zero address", async () => {
        await expectRevert(
            instance.safeTransferFrom(accounts[2], constants.ZERO_ADDRESS, 0, 1, [], { from: accounts[2] }),
            "ERC1155: transfer to the zero address"
        )
    });

    // setApprovalForAll

    it("should emit approval for all message", async () => {
        const receipt = await instance.setApprovalForAll(accounts[1], true, { from: accounts[2] });

        expectEvent(receipt, 'ApprovalForAll', {
            account: accounts[2],
            operator: accounts[1],
            approved: true
        });
    });

    it("should revert as owner is caller", async () => {
        await expectRevert(
            instance.setApprovalForAll(accounts[1], true, { from: accounts[1] }),
            "ERC1155: setting approval status for self"
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
        const response = await instance.balanceOf(accounts[2], 0);
        assert.equal(1, response.toNumber());
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