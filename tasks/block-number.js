const { task } = require("hardhat/config");

task("block-number", "Prints the current block number").setAction(
  // const blockTask = async function() => {} //option 1 to define
  // async function blockTask() {} //option 2 to define

  //anonymous function in javascript
  //here we dont have taskArgs
  //hre is hardhat run time environment
  async (taskArgs, hre) => {
    const blockNumber = await hre.ethers.provider.getBlockNumber();
    console.log(`Current block number: ${blockNumber}`);
  },
);

module.exports = {};

// you can even get a task to check account balance
// --> important for fyp, find it in the hardhat documentation
