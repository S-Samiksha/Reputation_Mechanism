// hardhat-deploy library
const { assert, expect } = require("chai");
const { network, deployments, ethers, getNamedAccounts } = require("hardhat");

describe("FundMe", async function () {
  let fundMe, deployer, mockV3Aggregator;
  beforeEach(async function () {
    //const accounts = await ethers.getSigners()

    deployer = (await getNamedAccounts()).deployer;
    await deployments.fixture(["all"]);
    fundMe = await ethers.getContract("FundMe", deployer); //give most recently deployed contract of Fundme
    mockV3Aggregator = await ethers.getContract("MockV3Aggregator", deployer);
  });
  describe("constructor", async function () {
    it("sets the aggregator addresses correctly", async function () {
      const response = await fundMe.priceFeed();
      assert.equal(response, mockV3Aggregator.target);
    });
  });
  describe("fund", function () {
    // https://ethereum-waffle.readthedocs.io/en/latest/matchers.html
    // could also do assert.fail
    it("Fails if you don't send enough ETH", async () => {
      await expect(fundMe.fund()).to.be.revertedWith(
        "You need to spend more ETH!",
      );
    });
    // we could be even more precise here by making sure exactly $50 works
    // but this is good enough for now
    it("Updates the amount funded data structure", async () => {
      const sendValue = ethers.parseEther("1");
      await fundMe.fund({ value: sendValue });
      const response = await fundMe.addressToAmountFunded(deployer);
      assert.equal(response.toString(), sendValue.toString());
    });
    it("Adds funder to array of funders", async () => {
      const sendValue = ethers.parseEther("1");
      await fundMe.fund({ value: sendValue });
      const response = await fundMe.funders(0);
      assert.equal(response, deployer);
    });
  });
  describe("withdraw", function () {
    //automatically fund the contract before we conduct any test
    beforeEach(async () => {
      const sendValue = ethers.parseEther("1");
      await fundMe.fund({ value: sendValue });
    });

    it("withdraws ETH from a single funder", async () => {
      // Arrange
      const startingFundMeBalance = await ethers.provider.getBalance(
        fundMe.target,
      );
      const startingDeployerBalance =
        await ethers.provider.getBalance(deployer);

      // Act
      const transactionResponse = await fundMe.withdraw();
      const transactionReceipt = await transactionResponse.wait(1);
      const { gasUsed, effectiveGasPrice } = transactionReceipt;
      const gasCost = gasUsed.mul(effectiveGasPrice);

      const endingFundMeBalance = await ethers.provider.getBalance(
        fundMe.target,
      );
      const endingDeployerBalance = await ethers.provider.getBalance(deployer);

      // Assert
      // Maybe clean up to understand the testing
      assert.equal(endingFundMeBalance, 0);
      assert.equal(
        startingFundMeBalance.add(startingDeployerBalance).toString(),
        endingDeployerBalance.add(gasCost).toString(),
      );
    });
    // this test is overloaded. Ideally we'd split it into multiple tests
    // but for simplicity we left it as one
    it("is allows us to withdraw with multiple funders", async () => {
      // Arrange
      const accounts = await ethers.getSigners();
      const sendValue = ethers.parseEther("1");
      for (i = 1; i < 6; i++) {
        const fundMeConnectedContract = await fundMe.connect(accounts[i]);
        await fundMeConnectedContract.fund({ value: sendValue });
      }
      const startingFundMeBalance = await ethers.provider.getBalance(
        fundMe.target,
      );
      const startingDeployerBalance =
        await fundMe.provider.getBalance(deployer);

      // Act
      const transactionResponse = await fundMe.cheaperWithdraw();
      // Let's comapre gas costs :)
      // const transactionResponse = await fundMe.withdraw()
      const transactionReceipt = await transactionResponse.wait();
      const { gasUsed, effectiveGasPrice } = transactionReceipt;
      const withdrawGasCost = gasUsed.mul(effectiveGasPrice);
      console.log(`GasCost: ${withdrawGasCost}`);
      console.log(`GasUsed: ${gasUsed}`);
      console.log(`GasPrice: ${effectiveGasPrice}`);
      const endingFundMeBalance = await fundMe.provider.getBalance(
        fundMe.target,
      );
      const endingDeployerBalance = await fundMe.provider.getBalance(deployer);
      // Assert
      assert.equal(
        startingFundMeBalance.add(startingDeployerBalance).toString(),
        endingDeployerBalance.add(withdrawGasCost).toString(),
      );
      // Make a getter for storage variables
      await expect(fundMe.getFunder(0)).to.be.reverted;

      for (i = 1; i < 6; i++) {
        assert.equal(
          await fundMe.getAddressToAmountFunded(accounts[i].address),
          0,
        );
      }
    });
    it("Only allows the owner to withdraw", async function () {
      const accounts = await ethers.getSigners();
      const fundMeConnectedContract = await fundMe.connect(accounts[1]);
      await expect(fundMeConnectedContract.withdraw()).to.be.revertedWith(
        "FundMe__NotOwner",
      );
    });
  });
});