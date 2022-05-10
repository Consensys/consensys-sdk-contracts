const BasicNFT = artifacts.require("BasicNFT");

contract("BasicNFT", async (accounts) => {
    let instance;

    beforeEach(async () => {
        instance = await BasicNFT.deployed();
    });

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

    it("should mint a new token", async () => {
        const tokenURIToStore = "ipfs://mysuperhash/0";
        await instance.mintWithTokenURI(accounts[1], tokenURIToStore, { from: accounts[0] });

        const balanceOfAccount1 = await instance.balanceOf.call(accounts[1]);
        assert.equal(1, balanceOfAccount1.toString());

        const tokenURI = await instance.tokenURI.call(0);
        assert.equal(tokenURIToStore, tokenURI);
    });

    it("should fail because account is not allowed to mint", async () => {
        try {
            await instance.mintWithTokenURI(accounts[1], "ipfs://mysuperhash/0", { from: accounts[1] });
        } catch (e) {
            assert.include(e.message, "is missing role");
        }
    });
});