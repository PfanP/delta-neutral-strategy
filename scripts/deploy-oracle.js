const {
    ethers,
    upgrades
} = require("hardhat");
const {
    toChecksumAddress
} = require("ethereum-checksum-address")


// NOTE: bonding needs to be added as a CNV minter for bonds.policyUpdate() to work
// @dev npx hardhat verify <CONTRACT_ADDRESS> --network <NETWORK_NAME>

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer Address: ", deployer.address);

    // /* -------------------------------------------------------------------------- */
    // /*                              DEPLOY ORACLE                                  */
    // /* -------------------------------------------------------------------------- */
    const oracle = await ethers.getContractFactory("ConcaveOracle");
    console.log("Deploying ConcaveOracle...");
    const concaveOracle = await oracle.deploy();
    await concaveOracle.deployed();
    console.log("ConcaveOracle Address: ", concaveOracle.address);
}
main();