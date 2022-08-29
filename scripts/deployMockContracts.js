const {
    ethers,
    upgrades
} = require("hardhat");
const hre = require("hardhat");
const {
    toChecksumAddress
} = require("ethereum-checksum-address")
const {
    BigNumber
} = require("ethers");
const {
    abi
} = require("../out/src/contracts/oracle/MockERC20.sol/MockERC20.json");

const deployedContractAddresses = require('./deployed_contracts.js');

// NOTE: bonding needs to be added as a CNV minter for bonds.policyUpdate() to work
// @dev npx hardhat verify <CONTRACT_ADDRESS> --network <NETWORK_NAME>

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer Address: ", deployer.address);

    const emptyAddress = "0x0000000000000000000000000000000000000000";
    // /* -------------------------------------------------------------------------- */
    // /*                              DEPLOY ORACLE                                  */
    // /* -------------------------------------------------------------------------- */
    const mockDAI = await getMockERC20();
    const oracle = await getOracle();
    const vault = await getVault(mockDAI, deployer.address, deployer.address, deployer.address, deployer.address, emptyAddress);
    const strategy = await deployForSolidity("MockStrategy",
        vault.address, // _vault
        emptyAddress, // _homoraBank
        emptyAddress, // _sushiSwapSpell
        emptyAddress, // _uniswapV2Router
        mockDAI.address, // _token1
        BigNumber.from("2000000000000000000"), // _farmLeverage
        oracle.address, // _concaveOracle
        emptyAddress, // _lpToken
        0, // _pid
        emptyAddress // _ethTokenAddress
    );
    console.log("deployedStrategy Address: ", strategy.address);

    const addStrategyResp = await vault.addStrategy(strategy.address, 1000, 0, 1000, 0);
    await addStrategyResp.wait();
    console.log("addStrategyResp sucessfully");
}

async function getVault(mockERC20, governance, rewards, guardian, management, healthCheck) {
    if (deployedContractAddresses.Vault == undefined) {
        const vault = await deployForVyper("Vault");
        const initilizeResp = await vault.initialize(
            mockERC20.address,
            governance,
            rewards,
            "MockVault",
            "CNVV",
            guardian,
            management,
            healthCheck
        )
        await initilizeResp.wait();
        console.log("vault initilize sucessfully");
        return vault;
    } else {
        const vault = ethers.getContractAt(abi, deployedContractAddresses.Vault);
        console.log("vault Address: ", deployedContractAddresses.Vault);
        return vault;
    }
}

async function getMockERC20() {
    if (deployedContractAddresses.MockERC20 == undefined) {
        const mockERC20 = await deployForSolidity("MockERC20", "MockDAI", "MDAI");
        return mockERC20;
    } else {
        const mockERC20 = ethers.getContractAt(abi, deployedContractAddresses.MockERC20);
        console.log("mockERC20 Address: ", deployedContractAddresses.MockERC20);
        return mockERC20;
    }
}


async function getOracle() {
    if (deployedContractAddresses.ConcaveOracle == undefined) {
        const deviation = "1500000000000000000"
        const oracle = await deployForSolidity("ConcaveOracle");
        const baseOracle = await deployForSolidity("MockConcaveOracle");

        const tokens = [mockDAI.address]
        const deviations = [BigNumber.from(deviation)]
        const oracles = [
            [baseOracle.address, baseOracle.address]
        ]
        const addPrimarySource = await oracle.addPrimarySource(tokens, deviations, oracles);
        await addPrimarySource.wait();
        return oracle;
    } else {
        const oracle = ethers.getContractAt(abi, deployedContractAddresses.ConcaveOracle);
        console.log("oracle Address: ", deployedContractAddresses.ConcaveOracle);
        return oracle;
    }
}

async function deployForVyper(contractName) {
    const contract = await deploy(contractName, false);
    return contract;
}

async function deployForSolidity(contractName, ...args) {
    if (contractName == "MockERC20") {

    }
    const contract = await deploy(contractName, true, ...args);
    return contract;
}

async function deploy(contractName, needVerify, ...args) {
    console.log(`Deploying ${contractName}..., with args: ${args}`);
    const contract = await ethers.getContractFactory(contractName);
    console.log("Deploying" + contractName);
    var deployedContract = undefined;
    if (args == undefined) {
        deployedContract = await contract.deploy();
    } else {
        deployedContract = await contract.deploy(...args);
    }
    await deployedContract.deployed();
    console.log(contractName + "Address: ", deployedContract.address);
    if (needVerify) {
        console.log("ready to verify" + contractName, "wait 10 secs");
        setTimeout(async () => {
            await hre.run("verify:verify", {
                address: deployedContract.address,
                constructorArguments: args,
            });
        }, 10000);
    }
    return deployedContract;
}
main();