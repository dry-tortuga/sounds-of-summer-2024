const fs = require("fs");
const { ethers } = require("hardhat");

// Load the contract ABI

const { abi } = JSON.parse(fs.readFileSync("./artifacts/contracts/SoundsOfSummer2024.sol/SoundsOfSummer2024.json"));

async function main() {

	const [deployer] = await ethers.getSigners();

	const owner = deployer.address;

	console.log("---------------------------------------------------------------")

	console.log(`Deploying SoundsOfSummer2024 contract with account=${owner}...`);

	const tx = await ethers.deployContract("SoundsOfSummer2024");

	await tx.waitForDeployment();

	console.log(tx);

	console.log(`SoundsOfSummer2024 contract with owner=${owner} deployed to ${tx.target}!`);

	console.log("---------------------------------------------------------------")

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
