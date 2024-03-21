const {
	time,
	loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

// https://hardhat.org/hardhat-chai-matchers/docs/reference

describe("SoundsOfSummer2024", () => {

	// We define a fixture to reuse the same setup in every test.
	// We use loadFixture to run this setup once, snapshot that state,
	// and reset Hardhat Network to that snapshot in every test.
	async function deployContractFixture() {

		// Contract is deployed using the first signer/account by default
		const [owner, otherAccount] = await ethers.getSigners();

		// Contract is deployed with an initial balance of 10 ETH

		const SoundsOfSummer2024 = await ethers.getContractFactory("SoundsOfSummer2024");
		const contract = await SoundsOfSummer2024.deploy();

		return { contract, owner, otherAccount };

	}

	describe("Deployment", () => {

		it("Should set the right contract owner", async () => {

			const { contract, owner } = await loadFixture(deployContractFixture);

			expect(await contract.owner()).to.equal(owner.address);

		});

	});

	describe("tokenURI", () => {

		it("Should update the base URI if called by the contract owner", async () => {

			const { contract, owner, otherAccount } = await loadFixture(deployContractFixture);

			await contract.publicMint(1);

			const result = await contract.tokenURI(0);

		});

	});

	describe("MerkleProof", function () {

		it("only whitelisted address can call function", async function () {

			let owner, addr1, addr2;
			let merkleTreeContract;
			let rootHash =
			"0x12014c768bd10562acd224ac6fb749402c37722fab384a6aecc8f91aa7dc51cf";

			// async function setup() {
			[owner, addr1, addr2] = await ethers.getSigners();

			const MerkleTree = await ethers.getContractFactory("MerkleProofContract");
			merkleTreeContract = await MerkleTree.deploy(rootHash);
			console.log(merkleTreeContract.address);
			// }

			// beforeEach(async function () {
			//   await setup();
			// });

			const user = addr1;

			const proof = [
			"0xe9707d0e6171f728f7473c24cc0432a9b07eaaf1efed6a137a4a8c12c79552d9",
			"0x1ebaa930b8e9130423c183bf38b0564b0103180b7dad301013b18e59880541ae",
			];

			console.log(
			`user address: ${user.address} and proof: ${proof} and rootHash: ${rootHash}`
			);

			expect(
			await merkleTreeContract.connect(user).onlyWhitelisted(proof)
			).to.equal(5);

			await expect(
			merkleTreeContract.connect(addr2).onlyWhitelisted(proof)
			).to.be.revertedWith("Not WhiteListed Address");

		});

	});

});
