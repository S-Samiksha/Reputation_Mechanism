const { ethers, network } = require("hardhat");
const fs = require("fs");

const FRONT_END_ADDRESSES_FILE =
  "../reputation_mechanism_frontend/constants/contractAddress.json";

const FRONT_END_ABI_FILE =
  "../reputation_mechanism_frontend/constants/abi.json";

module.exports = async function () {
  if (process.env.UPDATE_FRONT_END) {
    console.log("Updating front end...");
    updateContractAddresses();
    updateABI();
  }
};

async function updateABI() {
  const Store = await ethers.getContract("Store");
  fs.writeFileSync(FRONT_END_ABI_FILE, JSON.stringify(Store.interface));
}

async function updateContractAddresses() {
  const Store = await ethers.getContract("Store");
  const chainId = network.config.chainId.toString();
  const contractAddress = JSON.parse(
    fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8")
  );
  if (chainId in contractAddress) {
    if (!contractAddress[chainId].includes(Store.target)) {
      contractAddress[chainId].push(Store.target);
    }
  }
  {
    contractAddress[chainId] = [Store.target];
  }
  fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(contractAddress));
}
