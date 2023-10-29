require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-deploy");
require("@nomiclabs/hardhat-ethers");

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY || "key";
const SEPOLIA_PRIVATE_KEY_2 = process.env.SEPOLIA_PRIVATE_KEY_2 || "key";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "key";
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [SEPOLIA_PRIVATE_KEY, SEPOLIA_PRIVATE_KEY_2],
      chainId: 11155111,
      blockConfirmations: 6,
      gas: 5000000,
      gasPrice: 50000000000,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
  },
  solidity: {
    compilers: [{ version: "0.8.21" }, { version: "0.6.6" }],
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: false,
    outputFile: "gas-report.txt",
    noColors: true,
  },
  namedAccounts: {
    deployer: {
      default: 0, //the first account is the deployer account
    },
    userOne: {
      default: 1,
    },
    userTwo: {
      default: 2,
    },
    userThree: {
      default: 3,
    },
    //you can even add the different users here
  },
  mocha: {
    timeout: 500000,
  },
};
