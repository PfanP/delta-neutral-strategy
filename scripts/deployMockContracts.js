const {
    ethers,
    upgrades
} = require("hardhat");
const {
    toChecksumAddress
} = require("ethereum-checksum-address")
const { BigNumber } = require("ethers");

// NOTE: bonding needs to be added as a CNV minter for bonds.policyUpdate() to work
// @dev npx hardhat verify <CONTRACT_ADDRESS> --network <NETWORK_NAME>

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer Address: ", deployer.address);

    // /* -------------------------------------------------------------------------- */
    // /*                              DEPLOY ORACLE                                  */
    // /* -------------------------------------------------------------------------- */
    const mockDAI = "0xf2edF1c091f683E3fb452497d9a98A49cBA84666";
    const mockWETH = "0xce88D2C5D5a2efe7AE1024D9D34A32a753C1C719";
    const deviation = "1500000000000000000"
    const emptyAddress = "0x0000000000000000000000000000000000000000";


    const oracle = await deploy("ConcaveOracle");
    const baseOracle = await deploy("MockConcaveOracle");

    const tokens = [mockDAI, mockWETH]
    const deviations = [BigNumber.from(deviation), BigNumber.from(deviation)]
    const oracles = [[baseOracle.address, baseOracle.address], [baseOracle.address, baseOracle.address]]

    await oracle.addPrimarySource(tokens, deviations, oracles);

    const vault = await deploy("Vault");
    const strategy = await deploy("Strategy",
    {
        _vault: vault.address,
        _homoraBank: emptyAddress,
        _sushiSwapSpell: emptyAddress,
        _uniswapV2Router: emptyAddress,
        _token1: mockDAI,
        _farmLeverage: BigNumber.from("2000000000000000000"),
        _concaveOracle: oracle.address,
        _lpToken: emptyAddress,
        _pid: 0,
        _ethTokenAddress: mockWETH
    }
    );
    await vault.initialize(
        [mockDAI,
        deployer.address,
        emptyAddress,
        "MockVault",
        "CNVV",
        deployer.address,
        deployer.address,
        emptyAddress]
    )
    await vault.addStrategy(strategy.address, 1000, 0, 1000, 0);
}

async function deploy(contractName, args) {
    console.log(`Deploying ${contractName}..., with args: ${args}`);
    const contract = await ethers.getContractFactory(contractName);
    console.log("Deploying" + contractName);
    const deployedContract = await contract.deploy(args);
    await deployedContract.deployed();
    console.log(contractName + "Address: ", deployedContract.address);
    return deployedContract;
}
main();