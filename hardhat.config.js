require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-interface-generator");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./src/contracts",
    tests: "src/test",
    artifacts: "out",
  },
  networks: {
    polygon: {
      url: process.env.POLYGON_ALCHEMY,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  ignoreFiles: ["./src/test/*", "./lib/*"],
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
