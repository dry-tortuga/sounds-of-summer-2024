const keccak256 = require("keccak256");
const { default: MerkleTree } = require("merkletreejs");
const fs = require("fs");

const allowList = require('../constants/allowListInput.json').addresses;

// Hash and store the addresses as leafs in the merkle tree
const leaves = allowList.map((address) => keccak256(address));

// Construct the merkle tree
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// Utility Function to Convert From Buffer to Hex
const bufferToHex = (x) => "0x" + x.toString("hex");

// Get the hash value for the merkle tree root
var root = bufferToHex(tree.getRoot())

// Build the final JSON data for the address, leaf hash, and merkle proof

const allowListJSON = { root, data: [] };

allowList.forEach((address) => {

	const leaf = keccak256(address);

	const proof = tree.getProof(leaf).map((x) => bufferToHex(x.data));

	allowListJSON.data.push({
		address: address,
		leaf: bufferToHex(leaf),
		proof,
	});

});

// Store the final JSON data

fs.writeFile(`./constants/allowListOutput.json`, JSON.stringify(allowListJSON, null, 2), (err) => {
	if (err) {
		throw err;
	}
});

console.log(`Root Hash: ${root}`);
