const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const { soliditySha3, keccak256 } = require("web3-utils");
const { BigNumber } = ethers;

describe("ExoDistributor", function () {
	before(async function () {
		this.ExoDistributor = await ethers.getContractFactory("ExoDistributor");
		this.ERC721 = await ethers.getContractFactory("TestERC721");

		this.signers = await ethers.getSigners();
		this.deployer = this.signers[0];
		this.dev = this.signers[1];
		this.alice = this.signers[2];
		this.bob = this.signers[3];
		this.carol = this.signers[4];
		this.protocolMultisig = this.signers[5];
		this.feeMultisig = this.signers[6];

		this.distributor = await this.ExoDistributor.deploy();
		await this.distributor.deployed();
		this.erc721 = await this.ERC721.deploy();
        await this.erc721.deployed();

		this.whitelisted = this.signers.slice(0, 5);
		this.notWhitelisted = this.signers.slice(5, 10);

		let leaves = this.whitelisted.map((sig, i) => soliditySha3(sig.address, i + 1));
		this.tree = new MerkleTree(leaves, keccak256, { sort: true });
    });

	beforeEach(async function () {
	});

	it("add collection", async function () {
		await expect(await this.distributor.getTotalMinted()).to.eql(BigNumber.from(0));
		const merkleRoot = this.tree.getHexRoot();

		await expect(
			this.distributor
				.connect(this.deployer)
				.addCollection(this.erc721.address, true, 10, merkleRoot)
		).to.not.be.reverted;
		await expect(
			this.distributor
				.connect(this.dev)
				.addCollection(this.erc721.address, true, 10, merkleRoot)
		).to.be.revertedWith("Ownable: caller is not the owner");
	});

	it("mint", async function () {
		const merkleProof = this.tree.getHexProof(
			soliditySha3(this.whitelisted[0].address, 1)
		);
		const merkleProof1 = this.tree.getHexProof(
			soliditySha3(this.whitelisted[1].address, 2)
		);
		const invalidMerkleProof1 = this.tree.getHexProof(
			soliditySha3(this.whitelisted[1], 1)
		);
		const invalidMerkleProof2 = this.tree.getHexProof(
			soliditySha3(this.notWhitelisted[0], 1)
		);

		await expect(await this.distributor.getTotalMinted()).to.eql(BigNumber.from(0));
		await expect(
			this.distributor
				.connect(this.deployer)
				.claim(this.erc721.address, 1, merkleProof, { value: 11 })
		).to.be.revertedWith(
			"ERC721PresetMinterPauserAutoId: must have minter role to mint"
		);
		await expect(await this.distributor.getTotalMinted()).to.equal(0);

		await this.erc721.setupMinterRole(this.distributor.address);
		await expect(
			this.distributor
				.connect(this.deployer)
				.claim(this.erc721.address, 1, merkleProof, { value: 11 })
		).to.be.not.reverted;
		await expect(await this.distributor.getTotalMinted()).to.equal(1);
		await expect(
			await this.distributor.getCollectionInfo(this.erc721.address)
		).to.eql([
			BigNumber.from(10),
			true,
			BigNumber.from(1),
			BigNumber.from(10000),
			BigNumber.from(1),
		]);

		await expect(
			this.distributor
				.connect(this.deployer)
				.claim(this.erc721.address, 1, merkleProof)
		).to.be.revertedWith("ExoDistributor: Reached to Mint Limit");
		await expect(
			this.distributor
				.connect(this.dev)
				.claim(this.erc721.address, 2, merkleProof1, { value: 9 })
		).to.be.reverted; // Insiffucient Funds
		await expect(
			this.distributor
				.connect(this.whitelisted[1])
				.claim(this.erc721.address, 1, invalidMerkleProof1)
		).to.be.revertedWith("ExoDistributor: Invalid proof.");
		await expect(
			this.distributor
				.connect(this.notWhitelisted[0])
				.claim(this.erc721.address, 1, invalidMerkleProof2)
		).to.be.revertedWith("ExoDistributor: Invalid proof.");
	});
});
