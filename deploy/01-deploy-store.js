const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
const { network, ethers } = require("hardhat");
const { verify } = require("../utils/verify");
//main function

module.exports = async ({ getNamedAccounts, deployments }) => {
  //get these variables from hre
  const { deploy, log } = deployments;

  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  log("----------------------------------------------------");
  log("Deploying Store and waiting for confirmations...");

  const Store = await deploy("Store", {
    from: deployer,
    //Arguments: reservePrice, currentPrice, NumberofAlgos
    args: [],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  log(`Store Contract deployed at ${Store.address}`);
  log("Verifying...");

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(Store.address);
  }
};

module.exports.tags = ["all", "Store"];
