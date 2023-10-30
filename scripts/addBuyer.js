const { ethers, getNamedAccounts } = require("hardhat");

async function main() {
  const { userTwo } = await getNamedAccounts();
  const Store = await ethers.getContract("Store", userTwo);
  console.log(`Got contract Store at ${Store.target}`);
  console.log("Adding Buyer...");
  const transactionResponse = await Store.createBuyer("Buyer_1");
  await transactionResponse.wait();
  console.log("Added Buyer!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
