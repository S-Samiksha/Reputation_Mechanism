const { ethers, getNamedAccounts } = require("hardhat");

async function main() {
  const { userTwo } = await getNamedAccounts();
  const Store = await ethers.getContract("Store", userTwo);
  console.log(`Got contract Store at ${Store.target}`);
  console.log("Leaving Review...");
  const transactionResponse = await Store.buyerReview(60, 2);
  await transactionResponse.wait();
  console.log("Review Left!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
