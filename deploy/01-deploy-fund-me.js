// how to deploy the fund me contract

//import
const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
const { network } = require("hardhat");
const { verify } = require("../utils/verify");
//main function
//calling of main function

// function deployFunc() {
//   console.log("Hi!!");
// }

// module.exports.default = deployFunc;

//nameless async function

// passing the hardhat runtime environment
module.exports = async ({ getNamedAccounts, deployments }) => {
  //get these variables from hre
  const { deploy, log } = deployments;

  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  //   const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];

  // when going for localhost or hardhat network we want to use a mock

  let ethUsdPriceFeedAddress;
  if (developmentChains.includes(network.name)) {
    const ethUsdAggregator = await deployments.get("MockV3Aggregator"); //get is a command to get the address, because it is deployed
    ethUsdPriceFeedAddress = ethUsdAggregator.address;
  } else {
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  }
  log("----------------------------------------------------");
  log("Deploying FundMe and waiting for confirmations...");

  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: [ethUsdPriceFeedAddress],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  log(`FundMe deployed at ${fundMe.address}`);
  // we do not verify on local network
  // do not need to verify for FYP
  //   if (
  //     !developmentChains.includes(network.name) &&
  //     process.env.ETHERSCAN_API_KEY
  //   ) {
  //     await verify(fundMe.address, [ethUsdPriceFeedAddress]);
  //   }
};

module.exports.tags = ["all", "fundme"];
