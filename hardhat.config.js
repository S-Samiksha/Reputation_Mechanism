require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("./tasks/block-number");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-deploy");
require("@nomiclabs/hardhat-ethers");

const SEPOLIA_RPC_URL = process.env.RPC_URL;
const SEPOLIA_PRIVATE_KEY = process.env.PRIVATE_KEY || "key";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "key";
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [SEPOLIA_PRIVATE_KEY],
      chainId: 11155111,
      blockConfirmations: 5,
    },
    localhost: {
      url: "http://localhost:8545",
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
    //you can even add the different users here
  },
};
