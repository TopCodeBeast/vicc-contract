
const hre = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const { soliditySha3, keccak256 } = require("web3-utils");

async function main() {
  // We get the contract to deploy

  const BudToken = await hre.ethers.getContractFactory("BudToken");
  const BudTokenContract = await BudToken.deploy(['0xDFE055245aB0b67fB0B5AE3EA28CD1fee40299df'], ['0xDFE055245aB0b67fB0B5AE3EA28CD1fee40299df']);

  await BudTokenContract.deployed();
  
  console.log("BudTokenContract", BudTokenContract)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
