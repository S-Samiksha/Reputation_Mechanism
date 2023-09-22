//Import the dependencies from hardhat
const { ethers, run, network } = require("hardhat");

//async main function declaration
async function main() {
  const StoreFactory = await ethers.getContractFactory("Store");
  console.log("Deploying contract....");
  const ourStore = await StoreFactory.deploy();
  await ourStore.waitForDeployment();

  console.log(`Deployed contract to: ${ourStore.target}`);

  // verifying the contract only if we are on Sepolia network.
  // test whether it is a live network
  // if (network.config.chainId == 11155111 && process.env.ETHERSCAN_API_KEY) {
  //   console.log("Waiting for block confirmations...");
  //   await ourStore.deploymentTransaction().wait(5); //wait for 5 blocks to be mined
  //   await verify(ourStore.target, []);
  // }

  //Interacting with the contract
  const currentValue = await ourStore.retrieve();
  console.log(`Current Value is: ${currentValue}`);
}

async function verify(contractAddress, args) {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    }); //run allows us to run any hardhat task
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already Verified!");
    } else {
      console.log(e);
    }
  }
}

//Run the Main
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
