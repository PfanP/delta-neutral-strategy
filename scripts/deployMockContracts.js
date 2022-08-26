const {
    ethers,
    upgrades
} = require("hardhat");
const {
    toChecksumAddress
} = require("ethereum-checksum-address")
const {
    BigNumber
} = require("ethers");
const {
    abi
} = require("../out/src/vyper_contracts/Vault.vy/Vault.json");

// NOTE: bonding needs to be added as a CNV minter for bonds.policyUpdate() to work
// @dev npx hardhat verify <CONTRACT_ADDRESS> --network <NETWORK_NAME>

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer Address: ", deployer.address);

    // /* -------------------------------------------------------------------------- */
    // /*                              DEPLOY ORACLE                                  */
    // /* -------------------------------------------------------------------------- */
    const mockDAI = "0xf2edF1c091f683E3fb452497d9a98A49cBA84666";
    const mockWETH = "0xf2edF1c091f683E3fb452497d9a98A49cBA84666";
    const deviation = "1500000000000000000"
    const emptyAddress = "0x0000000000000000000000000000000000000000";


    const oracle = await deploy("ConcaveOracle");
    const baseOracle = await deploy("MockConcaveOracle");

    const tokens = [mockDAI, mockWETH]
    const deviations = [BigNumber.from(deviation), BigNumber.from(deviation)]
    const oracles = [
        [baseOracle.address, baseOracle.address],
        [baseOracle.address, baseOracle.address]
    ]
    const addPrimarySource = await oracle.addPrimarySource(tokens, deviations, oracles);
    await addPrimarySource.wait();

    const vault = await deploy("Vault");
    // const vaultContract = await ethers.getContractAt(abi, vaultDeployed.address) 
    const initilizeResp = await vault.initialize(
        mockDAI,
        deployer.address,
        emptyAddress,
        "MockVault",
        "CNVV",
        deployer.address,
        deployer.address,
        emptyAddress
    )
    await initilizeResp.wait();
    console.log("vault initilize sucessfully");
    const strategy = await ethers.getContractFactory("MockStrategy");
    console.log("Deploying Strategy...");
    const deployedStrategy = await strategy.deploy(
        vault.address, // _vault
        emptyAddress, // _homoraBank
        emptyAddress, // _sushiSwapSpell
        emptyAddress, // _uniswapV2Router
        mockDAI, // _token1
        BigNumber.from("2000000000000000000"), // _farmLeverage
        oracle.address, // _concaveOracle
        emptyAddress, // _lpToken
        0, // _pid
        emptyAddress // _ethTokenAddress
    );
    await deployedStrategy.deployed();
    console.log("deployedStrategy Address: ", deployedStrategy.address);

    const addStrategyResp = await vault.addStrategy(deployedStrategy.address, 1000, 0, 1000, 0);
    await addStrategyResp.wait();
    console.log("addStrategyResp sucessfully");
}

async function deploy(contractName, ...args) {
    console.log(`Deploying ${contractName}..., with args: ${args}`);
    const contract = await ethers.getContractFactory(contractName);
    console.log("Deploying" + contractName);
    var deployedContract = undefined;
    if (args == undefined) {
        deployedContract = await contract.deploy();
    } else {
        deployedContract = await contract.deploy(args);
    }
    await deployedContract.deployed();
    console.log(contractName + "Address: ", deployedContract.address);
    return deployedContract;
}
main();
