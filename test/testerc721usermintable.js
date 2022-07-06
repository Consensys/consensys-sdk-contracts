const ERC721UserMintable = artifacts.require("ERC721UserMintable");
const {
    BN,           // Big Number support
    constants,    // Common constants, like the zero address and largest integers
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
  } = require('@openzeppelin/test-helpers');

contract("ERC721UserMintable", async (accounts) => {
    let instance;

    beforeEach(async () => {
        instance = await ERC721UserMintable.deployed();
    });

    // Instantiation

    it("should have owner be the deployer of the contract", async () => {
        const owner = await instance.owner();
        assert.equal(owner, accounts[0]);
    });

    it("should have the deployed name and symbol", async () => {
        const name = await instance.name.call();
        const symbol = await instance.symbol.call();
        const maxSupply = await instance.maxSupply.call();
        const price = await instance.price.call();
        assert.equal("My Test Payable NFT", name);
        assert.equal("MTPNFT", symbol);
        assert.equal(2, maxSupply.toNumber());
        assert.equal(10000000000, price.toNumber());
    });

    // Reserve

    it("should not let you reserve when exceeding max reserve amount", async () => {
        await expectRevert.unspecified(
            instance.reserve(21, { from: accounts[0] })
        );
    });

    it("should not let you reserve when exceeding max supply (max supply: 2)", async () => {
        await expectRevert.unspecified(
            instance.reserve(21, { from: accounts[0] })
        );
    });

    it("should not let you reserve as caller is not owner", async () => {
        await expectRevert(
            instance.reserve(1, { from: accounts[1] }),
            "Ownable: caller is not the owner"
        );
    });

    it("should let owner reserve one token", async () => {
        const receipt = await instance.reserve(1, { from: accounts[0] });

        const balanceOf = await instance.balanceOf.call(accounts[0]);
        assert.equal(1, balanceOf.toNumber());

        expectEvent(receipt, 'Transfer', {
            from: constants.ZERO_ADDRESS,
            to: accounts[0],
            tokenId: new BN(0),
        });
    });

    it("should toggle sale", async () => {
        const isActive = await instance.isSaleActive();
        assert.equal(false, isActive);
        await instance.toggleSale();
        const isActiveAfter = await instance.isSaleActive();
        assert.equal(true, isActiveAfter);
      });

    it("should mint a new token", async () => {
        const receipt = await instance.mint(1, { value: 10000000000, from: accounts[0] });
        const balance = await instance.balanceOf(accounts[0]);
    
        assert.equal(2, balance);

        expectEvent(receipt, 'Transfer', {
            from: constants.ZERO_ADDRESS,
            to: accounts[0],
            tokenId: new BN(1),
        });
      });

    it("should return owner address", async () => {
        const owner = await instance.ownerOf.call(0);
        assert.equal(accounts[0], owner);
    });

    it("should throw exception because token doesn't exist", async () => {
        try {
            await instance.ownerOf(1000);
        } catch (e) {
            assert.include(e.message, "ERC721: owner query for nonexistent token");
        }
    });

    // Approve

    it("should approve contract to other address", async () => {
        const approvedAddress = await instance.getApproved(0);
        
        if (approvedAddress !== '0x0000000000000000000000000000000000000000') {
            assert.fail("initial address is not zero address");
        }

        await instance.approve(accounts[2], 0, { from: accounts[0] });

        const approved = await instance.getApproved(0);
        assert.equal(accounts[2], approved);
    });

    it("should not let you approve to current owner", async () => {
        await expectRevert(
            instance.approve(accounts[0], 0, { from: accounts[0] }),
            "ERC721: approval to current owner",
          );
    });

    it("should not let you approve because sender is not the owner", async () => {
        await expectRevert(
            instance.approve(accounts[2], 0, { from: accounts[1] }),
            "ERC721: approve caller is not owner nor approved for all",
          );
    });

    // ContractURI

    it("should get the current contractURI", async () => {
        const uri = await instance.contractURI();
        assert.equal("", uri);
    });

    // SafeTransfer

    it("should let you safe transfer to new owner", async () => {
        const receipt = await instance.safeTransferFrom(accounts[0], accounts[2], 0, { from: accounts[0] });
        expectEvent(receipt, 'Transfer', {
            from: accounts[0],
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

    it("should revert as caller is not owner", async () => {
        try {
            await instance.setRoyalties(constants.ZERO_ADDRESS, 100, { from: accounts[1] });
        } catch (e) {
            assert.include(e.message, "Ownable: caller is not the owner");
        }
    });

    // View Methods

    it("should return correct balanceOf", async () => {
        const response = await instance.balanceOf(accounts[1]);
        assert.equal(1, response.toNumber());
    });

    it("should return true as is approved for all", async () => {
        const response = await instance.isApprovedForAll(accounts[2], accounts[1]);
        assert.equal(true, response);
    });

    // Roles

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
});
