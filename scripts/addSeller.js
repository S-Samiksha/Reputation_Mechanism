const { ethers, getNamedAccounts } = require("hardhat");

async function main() {
  const { userOne } = await getNamedAccounts();
  const Store = await ethers.getContract("Store", userOne);
  console.log(`Got contract Store at ${Store.target}`);
  console.log("Adding Seller...");
  const transactionResponse = await Store.createSeller("Seller_1");
  await transactionResponse.wait();
  console.log("Added Seller!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
