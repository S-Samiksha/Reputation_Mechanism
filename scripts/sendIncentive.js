const { ethers, getNamedAccounts } = require("hardhat");

async function main() {
  const { userTwo, userOne } = await getNamedAccounts();
  const Store = await ethers.getContract("Store", userOne);
  console.log(`Got contract Store at ${Store.target}`);
  console.log("Incentive...");
  console.log(userTwo);
  const transactionResponse = await Store.sendIncentive(userTwo, 1, {
    value: ethers.parseEther("0.0000000000000001"),
  });
  await transactionResponse.wait();
  console.log("Gave Incentive!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
