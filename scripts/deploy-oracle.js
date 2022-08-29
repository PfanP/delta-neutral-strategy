const { ethers, upgrades } = require("hardhat");
const { toChecksumAddress } = require("ethereum-checksum-address");

// NOTE: bonding needs to be added as a CNV minter for bonds.policyUpdate() to work
// @dev npx hardhat verify <CONTRACT_ADDRESS> --network <NETWORK_NAME>

async function main() {
  const SushiBaseStrategy = await ethers.getContractFactory(
    "SushiBaseStrategy"
  );
  const keyFragmentMint = await SushiBaseStrategy.deploy(
    "0x0aa7fb47469a8fee5615400de2d07db1ff96120d",
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
    "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
    0
  );
  const address = await keyFragmentMint.deployed();
}
main();
