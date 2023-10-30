const { ethers, getNamedAccounts } = require("hardhat");

async function main() {
  const { userTwo, userOne } = await getNamedAccounts();
  const Store = await ethers.getContract("Store", userTwo);
  console.log(`Got contract Store at ${Store.target}`);
  console.log("Buying product...");
  const transactionResponse = await Store.purchaseProduct(1, userOne, {
    value: ethers.parseEther("0.0000000000000001"),
  });
  await transactionResponse.wait();
  console.log("Purchased Product!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
