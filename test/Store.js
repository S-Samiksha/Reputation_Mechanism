const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const {
  time,
  helpers,
} = require("../node_modules/@nomicfoundation/hardhat-network-helpers");

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("store", function () {
      let Store_d;
      let Store_u_1;
      let Store_u_2;
      let Store_u_3;
      let Store_u_4;
      let deployer;
      let userOne;
      let userTwo;
      let userThree;
      let userFour;

      beforeEach(async () => {
        // const accounts = await ethers.getSigners()
        // deployer = accounts[0]
        deployer = (await getNamedAccounts()).deployer;
        userOne = (await getNamedAccounts()).userOne;
        userTwo = (await getNamedAccounts()).userTwo;
        userThree = (await getNamedAccounts()).userThree;
        userFour = (await getNamedAccounts()).userFour;
        await deployments.fixture("all");

        Store_d = await ethers.getContract("Store", deployer);
        Store_u_1 = await ethers.getContract("Store", userOne);
        Store_u_2 = await ethers.getContract("Store", userTwo);
        Store_u_3 = await ethers.getContract("Store", userThree);
        Store_u_4 = await ethers.getContract("Store", userFour);
      });

      describe("Adding Sellers Function Unit Test", function () {
        it("Adds the seller correctly", async () => {
          await Store_u_1.createSeller("Seller_1");
          const response0 = await Store_d.retrieveTotalSellers();
          const response1 = await Store_d.retrieveSellerID(userOne);
          const response2 = await Store_d.retrieveSellerName(userOne);
          assert.equal(response0, 1);
          assert.equal(response1, 1);
          assert.equal(response2, "Seller_1");
        });
        it("Checks if the seller exists", async () => {
          await Store_u_1.createSeller("Seller_1");
          const response0 = await Store_d.retrieveTotalSellers();
          const response1 = await Store_d.retrieveSellerID(userOne);
          const response2 = await Store_d.retrieveSellerName(userOne);
          assert.equal(response0, 1);
          assert.equal(response1, 1);
          assert.equal(response2, "Seller_1");

          await expect(Store_u_1.createSeller("Seller_1")).to.be.revertedWith(
            "Seller with this wallet already exists!"
          );
        });
      });

      describe("Adding Buyers Function Unit Test", function () {
        it("Adds the Buyers correctly", async () => {
          await Store_u_1.createBuyer("Buyer_1");
          const response0 = await Store_d.retrieveTotalBuyers();
          const response1 = await Store_d.retrieveBuyerID(userOne);
          const response2 = await Store_d.retrieveBuyerName(userOne);
          assert.equal(response0, 1);
          assert.equal(response1, 1);
          assert.equal(response2, "Buyer_1");
        });
        it("Checks if the Buyers exists", async () => {
          await Store_u_1.createBuyer("Buyer_1");
          const response0 = await Store_d.retrieveTotalBuyers();
          const response1 = await Store_d.retrieveBuyerID(userOne);
          const response2 = await Store_d.retrieveBuyerName(userOne);
          assert.equal(response0, 1);
          assert.equal(response1, 1);
          assert.equal(response2, "Buyer_1");

          await expect(Store_u_1.createBuyer("Buyer_1")).to.be.revertedWith(
            "Buyer with this wallet already exists!"
          );
        });
      });

      describe("Adding Sellers and Products", function () {
        it("Does not allow non-sellers to add products", async () => {
          await expect(
            Store_u_1.uploadProduct("Product_1", 100)
          ).to.be.revertedWith("Seller with this wallet does not exists!");
        });

        it("Adds the seller and its product correctly", async () => {
          await Store_u_1.createSeller("Seller_1");
          const response0 = await Store_d.retrieveTotalSellers();
          const response1 = await Store_d.retrieveSellerID(userOne);
          const response2 = await Store_d.retrieveSellerName(userOne);
          assert.equal(response0, 1);
          assert.equal(response1, 1);
          assert.equal(response2, "Seller_1");

          await Store_u_1.uploadProduct("Product_1", 100);
          const response3 = await Store_d.viewProductPrice(userOne, 1);
          assert.equal(response3, 100);
          const response4 = await Store_d.viewProductName(userOne, 1);
          assert.equal(response4, "Product_1");
        });
      });

      describe("Adding Sellers and Products Followed by a Buyer buying it", function () {
        beforeEach(async () => {
          await Store_u_1.createSeller("Seller_1");
          await Store_u_1.uploadProduct("Product_1", 100);
          await Store_u_2.createBuyer("Buyer_1");
        });
        it("Buyer sends the incorrect amount to purchase", async () => {
          await expect(
            Store_u_2.purchaseProduct(1, userOne)
          ).to.be.revertedWith(
            "Ethers not enough/too much to buy the product!"
          );
        });
        it("Buyer asks for a product that the seller does not have", async () => {
          await expect(
            Store_u_2.purchaseProduct(0, userOne)
          ).to.be.revertedWith("The Product does not exist!");
        });
        it("Buyer asks for a seller that does not exist", async () => {
          await expect(
            Store_u_2.purchaseProduct(0, userTwo)
          ).to.be.revertedWith("The Product does not exist!");
        });
        it("Buyer does not exist", async () => {
          await expect(
            Store_u_3.purchaseProduct(0, userOne)
          ).to.be.revertedWith("This buyer does not exist!");
        });

        it("Buyer sends the correct amount of ETH", async () => {
          const userTwoBalanceStart = await ethers.provider.getBalance(userTwo);

          const userOneBalanceStart = await ethers.provider.getBalance(userOne);
          const transactionResponse = await Store_u_2.purchaseProduct(
            1,
            userOne,
            {
              value: ethers.parseEther("0.0000000000000001"),
            }
          );
          const transactionReceipt = await transactionResponse.wait(1);
          const { gasUsed, gasPrice } = transactionReceipt;
          const gasCost = gasUsed * gasPrice;

          const userTwoBalanceEnd = await ethers.provider.getBalance(userTwo);
          const response0 = await Store_d.viewTransactions_ProductID(
            userTwo,
            1
          );
          assert.equal(response0, 1); //purchased product1 from sellerID 1
          const response1 = await Store_d.viewTransactions_SellerID(userTwo, 1);

          assert.equal(response1, 1);

          const userOneBalanceEnd = await ethers.provider.getBalance(userOne);

          //buyer start - end = 100+ gascost
          assert.equal(userTwoBalanceStart - userTwoBalanceEnd - gasCost, 100); //Buyer has 100 wei less

          assert.equal(userOneBalanceEnd - userOneBalanceStart, 100); //Seller has 100 wei more
        });
      });

      describe("Adding Sellers and Products Followed by a Buyer buying it and reviewing it", function () {
        beforeEach(async () => {
          await Store_u_1.createSeller("Seller_1");
          await Store_u_1.uploadProduct("Product_1", 100);
          await Store_u_2.createBuyer("Buyer_1");
          await Store_u_2.purchaseProduct(1, userOne, {
            value: ethers.parseEther("0.0000000000000001"),
          });
        });
        it("Buyer does not exist in buyerReview(1)", async () => {
          await expect(Store_u_3.buyerReview(4, 0)).to.be.revertedWith(
            "This buyer does not exist!"
          ); //using seller address
        });
        it("Buyer does not exist in buyerReview(2)", async () => {
          await expect(Store_u_1.buyerReview(4, 0)).to.be.revertedWith(
            "This buyer does not exist!"
          ); //using non existent address
        });
        it("TransactionID does not exist in buyerReview", async () => {
          await expect(Store_u_2.buyerReview(4, 0)).to.be.revertedWith(
            "Buyer does not have this transaction ID!"
          ); //using seller address
        });
        it("TransactionID does not exist in buyerReview", async () => {
          await expect(Store_u_2.buyerReview(4, 2)).to.be.revertedWith(
            "Buyer does not have this transaction ID!"
          ); //using seller address
        });
      });
    });
