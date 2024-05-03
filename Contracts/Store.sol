// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Math.sol";
import "hardhat/console.sol";

contract Store {
    //REPUTATION MECHANISM

    ///--- Private Variables ---
    uint256 private totalSellers = 0;
    uint256 private totalBuyers = 0;
    uint256 private immutable A_VALUE_S = 50;
    uint256 private immutable B_VALUE_S = 300;
    uint256 private immutable C_VALUE_S = 900;
    uint256 private immutable BETA_S = 1; //this will be converted to 0.1
    uint256 private immutable A_VALUE = 50;
    uint256 private immutable B_VALUE = 100;
    uint256 private immutable C_VALUE = 300;
    uint256 private immutable BETA_1 = 99;
    uint256 private immutable BETA_2 = 4000;
    uint256 private immutable B_TOLERANCE = 12; //hours

    Math private MathLib; //importing Token
    address private MathLibAddress;


    //----- Structs -----

    struct Product {
        uint256 productID;
        string productName;
        address sellerAddress; // The product object has a sellerAddress reference
        uint256 productPrice; //in wei
        uint256 totalSold;
        bool isExist; //flag to determin whether the product exists 
        uint256 numOfReviewsGiven;
        uint256 review;
        uint256 X_Value;
    }

    struct Transaction {
        uint256 txnID;
        uint256 timeStampBought;
        uint256 timeStampReviewed;
        uint256 purchasedProductID;
        address sellerAddress;
        bool reviewed;
        bool receivedIncentive;
        bool isExist;
    }

    struct Seller {
        address sellerAddress;
        string sellerName;
        uint256 sellerID;
        bool isExist; //flag to determine whether the Seller exists
        mapping(uint256 => Product) sellerProducts; //using the productID to obtain the product ; 
        uint256 totalProducts;
        uint256 totalRevenue;
        uint256 numOfSales;
    }

    struct Buyer {
        address buyerAddress;
        string buyerName;
        uint256 buyerID; 
        bool isExist; //flag to determine whether the buyer exists 
        mapping(uint256 => Transaction) txnMade;
        uint256 numOfTxn;
        uint256 numOfReviewsGiven;
        uint256 lastReviewTime;
        uint256 repScore;
        uint256 X_Value;
    }

    //----- Mappings -----

    // Maps user address to Seller or Buyer account structs
    // Mapping buyerAddress to array of Products that they bought
    // mapping(address => Product[]) public buyerPurchasedProducts;

    mapping(address => Seller) private sellersList;
    mapping(address => Buyer) private buyersList;
    mapping(uint256 => address) private sellersListByID;


    //-----Events -----

    // Events allow for Etherscan.io to pick up on any state change in the contract. 
    // Note: Events have nothing to do with the FrontEnd UI built using react

    event createSellerEvent(
        string sellerName,
        address sellerAddress,
        uint256 sellerID
    );

    event createBuyerEvent(
        string buyerName,
        address buyerAddress,
        uint256 buyerID,
        uint256 repScore
    );

    event uploadProductEvent(
        string productName,
        uint256 price,
        uint256 productID,
        address sellerAddress,
        uint256 sellerID
    );

    event purchasedProductsEvent(
        uint256 txnID,
        uint256 productID,
        address sellerAddress,
        address buyerAddress,
        uint256 price
    );

    event buyerReviewEvent(
        uint256 productID,
        address sellerAddress,
        address buyerAddress,
        uint256 buyerRating,
        uint256 timeStamp,
        uint256 finalProductRating,
        uint256 totalReviews
    );

    event incentiveReceived(
        uint256 txnID,
        address buyerAddress, 
        address sellerAddress, 
        uint256 reward, 
        uint256 sellerRefund, 
        uint256 RepScore
        
    );

    /* Constructor to deploy the math library */
    constructor() {
        MathLib = new Math();
        MathLibAddress = address(MathLib);
    }

    /**
    The create seller function allows the wallet to register itself as a seller and give themselves a name
     */

    function createSeller(string memory _sellerName) public {
        require(
            !sellersList[msg.sender].isExist,
            "Seller with this wallet already exists!"
        );
        Seller storage newSeller = sellersList[msg.sender]; //get the object

        //set the variables
        newSeller.sellerAddress = msg.sender;
        newSeller.sellerName = _sellerName;
        newSeller.sellerID = ++totalSellers; 
        newSeller.isExist = true;
        newSeller.totalProducts = 0;
        newSeller.totalRevenue = 0;
        newSeller.numOfSales = 0;

        // sellersList[msg.sender] = newSeller;

        sellersListByID[newSeller.sellerID] = newSeller.sellerAddress;
        emit createSellerEvent(
            newSeller.sellerName,
            newSeller.sellerAddress,
            newSeller.sellerID
        );

        

        console.log("Seller Created at:", msg.sender);
    }



    /**
    The create buyer function allows the wallet to register itself as a buyer and give themselves a name
     */
    function createBuyer(string memory _buyerName) public {
        require(
            !buyersList[msg.sender].isExist,
            "Buyer with this wallet already exists!"
        );
        Buyer storage newBuyer = buyersList[msg.sender]; //get the object
        //set the variables
        newBuyer.buyerAddress = msg.sender;
        newBuyer.buyerName = _buyerName;
        newBuyer.buyerID = ++totalBuyers; //TODO: convert to wad
        newBuyer.isExist = true;
        newBuyer.numOfReviewsGiven = 0;
        newBuyer.numOfTxn = 0;
        newBuyer.X_Value = 1 * (10 ** 18);
        newBuyer.repScore = 0;
        newBuyer.lastReviewTime = block.timestamp;

        emit createBuyerEvent(
            newBuyer.buyerName,
            newBuyer.buyerAddress,
            newBuyer.buyerID,
            newBuyer.repScore
        );
    }


    /**
    The upload product function allows for a registered seller to upload a product with a product name and price in wei
     */
    function uploadProduct(string memory _productName, uint256 price) public {

        //only the currently connected wallet + must be registered seller can create products
        require(
            sellersList[msg.sender].isExist,
            "Seller with this wallet does not exists!"
        );

        Seller storage currentSeller = sellersList[msg.sender]; 

        Product storage newProduct = currentSeller.sellerProducts[
            ++currentSeller.totalProducts
        ];

        newProduct.productID = currentSeller.totalProducts;
        newProduct.productName = _productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.productPrice = price;
        newProduct.totalSold = 0;
        newProduct.review = 0;
        newProduct.X_Value = 1 * (10 ** 18);
        newProduct.isExist = true;

        currentSeller.sellerProducts[currentSeller.totalProducts] = newProduct;

        emit uploadProductEvent(
            newProduct.productName,
            newProduct.productPrice,
            newProduct.productID,
            newProduct.sellerAddress,
            currentSeller.sellerID
        );
    }

    /**
    The purchase product function allows registered wallets to purchase a product 
     */

    function purchaseProduct(
        uint256 productID,
        address sellerAddress
    ) public payable{
        require(buyersList[msg.sender].isExist, "This buyer does not exist!");
        require(
            sellersList[sellerAddress].sellerProducts[productID].isExist,
            "The Product does not exist!"
        );
        require(
            msg.value ==
                sellersList[sellerAddress]
                    .sellerProducts[productID]
                    .productPrice,
            "Ethers not enough/too much to buy the product!"
        );

        (bool callSuccess, ) = (payable(sellerAddress)).call{value: msg.value}(
            ""
        );
        require(callSuccess, "Failed to send ether");

        uint256 txnID = ++buyersList[msg.sender].numOfTxn;

        Transaction storage newTxn = buyersList[msg.sender].txnMade[txnID];
        newTxn.txnID = txnID;
        newTxn.timeStampBought = block.timestamp;
        newTxn.purchasedProductID = productID;
        newTxn.sellerAddress = sellerAddress;
        newTxn.reviewed = false;
        newTxn.receivedIncentive = false;
        newTxn.isExist = true;
        buyersList[msg.sender].txnMade[txnID] = newTxn;

        sellersList[sellerAddress].sellerProducts[productID].totalSold++;
        sellersList[sellerAddress].totalRevenue += msg.value;
        sellersList[sellerAddress].numOfSales += 1;

        emit purchasedProductsEvent(
            txnID,
            productID,
            sellerAddress,
            msg.sender,
            sellersList[sellerAddress].sellerProducts[productID].productPrice
        );

    }

    /**
    The buyer review function allows for a registered buyer who has already made a purchase to leave a review 
     */

    function buyerReview(uint256 buyerRating, uint256 txnID) public {
        require(buyersList[msg.sender].isExist, "This buyer does not exist!");

        require(
            buyersList[msg.sender].txnMade[txnID].isExist,
            "Buyer does not have this transaction ID!"
        );

        require(
            buyersList[msg.sender].txnMade[txnID].reviewed == false,
            "Buyer already reviewed this transaction ID!"
        );

        address sellerAddress = buyersList[msg.sender]
            .txnMade[txnID]
            .sellerAddress;

        uint256 productID = buyersList[msg.sender]
            .txnMade[txnID]
            .purchasedProductID;

        uint256 price = sellersList[sellerAddress]
            .sellerProducts[productID]
            .productPrice;

        /*
        For testing purposes, a time lapse of 1 minute is made to become 1 hour 
        60 seconds --> divide by 60 --> 1 min 
        12min is 12 hours
        13 min is 13 hours 
        */
        uint256 timepassed = (block.timestamp -
            buyersList[msg.sender].lastReviewTime) / 60; //convert seconds to minutes then to hours

        uint256 lastReviewTime = 0; //set back to 0

        /**
        try to find the last reviewtime of the same ProductID and same seller 
         */
        for (uint256 i = buyersList[msg.sender].numOfTxn; i >= 1; i--) {
            if (
                buyersList[msg.sender].txnMade[txnID].sellerAddress ==
                sellerAddress &&
                buyersList[msg.sender].txnMade[txnID].purchasedProductID ==
                productID &&
                buyersList[msg.sender].txnMade[txnID].reviewed
            ) {
                lastReviewTime = buyersList[msg.sender]
                    .txnMade[txnID]
                    .timeStampReviewed;
                break;
            }
        }

        uint256 timeSinceLastReview = 0; //declare variable 
        if (lastReviewTime == 0) {
            //means the buyer has never reviewed the product before
            //add weightage of 0
            timeSinceLastReview = B_TOLERANCE;
        } else {
            // convert to hours
            // block.timstamp is in seconds 
            /*
            For testing purposes, a time lapse of 1 minute is made to become 1 hour 
            60 seconds --> divide by 60 --> 1 min 
            12min is 12 hours
            13 min is 13 hours 

            For the actual purpose, 
            (seconds - x )/60/60
            */
            timeSinceLastReview = (block.timestamp - lastReviewTime) / 60;
        }

        //update XValue and Reputation Score of Buyers
        buyersList[msg.sender].X_Value = calculateXValue_Buyer(
            buyersList[msg.sender].X_Value,
            timepassed,
            price,
            timeSinceLastReview
            
        );
        buyersList[msg.sender].repScore = calculateRepScore_Buyer(
            buyersList[msg.sender].X_Value
        );

        //Update X value and Reputation score of sellers
        sellersList[sellerAddress]
            .sellerProducts[productID]
            .X_Value = calculateXValue_Product(
            sellersList[sellerAddress].sellerProducts[productID].X_Value,
            buyersList[msg.sender].repScore,
            buyerRating,
            sellersList[sellerAddress].sellerProducts[productID].review
        );
        sellersList[sellerAddress]
            .sellerProducts[productID]
            .review = calculateReview_Product(
            sellersList[sellerAddress].sellerProducts[productID].X_Value
        );

        sellersList[sellerAddress]
            .sellerProducts[productID]
            .numOfReviewsGiven++;

        buyersList[msg.sender].txnMade[txnID].reviewed = true;
        buyersList[msg.sender].txnMade[txnID].timeStampReviewed = block
            .timestamp;
        buyersList[msg.sender].lastReviewTime = block.timestamp;

        emit buyerReviewEvent(
            productID,
            sellerAddress,
            msg.sender,
            buyerRating,
            block.timestamp,
            sellersList[sellerAddress].sellerProducts[productID].review,
            sellersList[sellerAddress]
                .sellerProducts[productID]
                .numOfReviewsGiven
        );
        
    }

    /**
    The send incentive function allows a registered seller to send an incentive to the buyer who has left them a review 
     */


    function sendIncentive(address buyerAddress, uint256 txnID) public payable{
        //obtain all the values first
        uint256 reward = calculateIncentive(buyerAddress, txnID);

        address sellerAddress = buyersList[buyerAddress]
            .txnMade[txnID]
            .sellerAddress;


        
        require(
            msg.value > reward,
            "Ethers not enough/too much to buy the product!"
        );

        (bool callSuccess, ) = (payable(buyerAddress)).call{value: reward}(
            ""
        );
        require(callSuccess, "Failed to send ether");

        
        uint256 remainder = msg.value-reward;

        (bool callSuccessTwo, ) = (payable(msg.sender)).call{value: remainder}(
            ""
        );
        require(callSuccessTwo, "Failed to return remaining ether");

        
        buyersList[buyerAddress].txnMade[txnID].receivedIncentive = true; 
        uint256 repscore = buyersList[buyerAddress].repScore;

        emit incentiveReceived(
        txnID,
        buyerAddress, 
        sellerAddress, 
        reward,
        remainder, 
        repscore
        
        );
    }

    /**
    Calculation of reputation scores and review scores
    These are all private functions and not available from outside contract.
    These functions cannot be called by the front end. 
    */


    function calculateXValue_Product(
        uint256 oldX,
        uint256 repScore,
        uint256 rincoming,
        uint256 raverage
    ) private view returns (uint256 newX) {
        newX = MathLib.calculateX_Seller(
            oldX,
            repScore,
            rincoming,
            raverage,
            BETA_S
        );
    }

    function calculateReview_Product(
        uint256 newX
    ) private view returns (uint256 rating) {
        rating = MathLib.sigmoidal_calc(A_VALUE_S, B_VALUE_S, C_VALUE_S, newX);
        return rating;
    }

    function calculateXValue_Buyer(
        uint256 oldX,
        uint256 timeFromInActivity,
        uint256 price,
        uint256 timeFromLastReview
    ) private view returns (uint256 newX) {
        //in days
        if (timeFromInActivity > 16 * 24) {
            timeFromInActivity = 16;
        } else {
            timeFromInActivity = timeFromInActivity / 24; //convert to days
        }

        newX = MathLib.calculateX_Buyer(
            oldX,
            timeFromInActivity,
            price,
            timeFromLastReview,
            BETA_1,
            BETA_2,
            B_TOLERANCE
        );

        return newX;
    }

    function calculateRepScore_Buyer(
        uint256 newX
    ) private view returns (uint256 rep) {
        rep = MathLib.sigmoidal_calc(A_VALUE, B_VALUE, C_VALUE, newX);

        return rep;
    }


    function calculateIncentive(address buyerAddress, uint256 txnID) public view returns (uint256 reward){
        require(buyersList[buyerAddress].isExist, "This buyer does not exist!");

        require(
            buyersList[buyerAddress].txnMade[txnID].isExist,
            "Buyer does not have this transaction ID!"
        );

        require(
            buyersList[buyerAddress].txnMade[txnID].receivedIncentive == false,
            "Buyer already got incentive for this transaction ID!"
        );

        address sellerAddress = buyersList[buyerAddress]
            .txnMade[txnID]
            .sellerAddress;

        require(msg.sender == sellerAddress, "You did not sell to this buyer!");

        uint256 productID = buyersList[buyerAddress]
            .txnMade[txnID]
            .purchasedProductID;
     
        require(
            sellersList[msg.sender].sellerProducts[productID].isExist,
            "The Product does not exist!"
        );

        uint256 price = sellersList[sellerAddress]
            .sellerProducts[productID]
            .productPrice;

        uint256 repscore = buyersList[buyerAddress].repScore;

        reward = MathLib.calculateReward(repscore, price);



        return reward;
    
    }

    /**
     View and Pure Functions 
     To access the private variables via the front end
     */

    function retrieveTotalBuyers() public view returns (uint256) {
        return totalBuyers;
    }

    function retrieveTotalSellers() public view returns (uint256) {
        return totalSellers;
    }

    function retrieveSellerID(
        address _sellerAddress
    ) public view returns (uint256) {
        require(
            sellersList[_sellerAddress].isExist,
            "Seller with this wallet does not exists! "
        );
        return sellersList[_sellerAddress].sellerID;
    }

    function retrieveSellerName(
        address _sellerAddress
    ) public view returns (string memory) {
        require(
            sellersList[_sellerAddress].isExist,
            "Seller with this wallet does not exists! "
        );
        return sellersList[_sellerAddress].sellerName;
    }

    function retrieveSellerTotalProducts(
        address _sellerAddress
    ) public view returns (uint256) {
        require(
            sellersList[_sellerAddress].isExist,
            "Seller with this wallet does not exists! "
        );
        return sellersList[_sellerAddress].totalProducts;
    }

    function retrieveBuyerTotalTransactions(
        address _buyerAddress
    ) public view returns (uint256) {
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );
        return buyersList[_buyerAddress].numOfTxn;
    }

    function retrieveBuyerRepScore(
        address _buyerAddress
    ) public view returns (uint256) {
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );
        return buyersList[_buyerAddress].repScore;
    }

    function retrieveBuyerID(
        address _buyerAddress
    ) public view returns (uint256) {
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );
        return buyersList[_buyerAddress].buyerID;
    }

    function retrieveBuyerName(
        address buyerAddress
    ) public view returns (string memory) {
        return buyersList[buyerAddress].buyerName;
    }

    function viewProductPrice(
        address _sellerAddress,
        uint256 _productID
    ) public view returns (uint256) {
        //check whether the seller exists
        require(
            sellersList[_sellerAddress].isExist,
            "Seller with this wallet does not exists! "
        );
        //check whether the product exists
        require(
            sellersList[_sellerAddress].sellerProducts[_productID].isExist,
            "Seller with this product does not exists! "
        );
        //return the price
        return
            sellersList[_sellerAddress].sellerProducts[_productID].productPrice;
    }

    function viewProductName(
        address _sellerAddress,
        uint256 _productID
    ) public view returns (string memory) {
        //check whether the seller exists
        require(
            sellersList[_sellerAddress].isExist,
            "Seller with this wallet does not exists! "
        );
        //check whether the product exists
        require(
            sellersList[_sellerAddress].sellerProducts[_productID].isExist,
            "ProductID in the seller does not exists! "
        );
        //return the price
        return
            sellersList[_sellerAddress].sellerProducts[_productID].productName;
    }

    function viewProductReview(
        address _sellerAddress,
        uint256 _productID
    ) public view returns (uint256) {
        //check whether the seller exists
        require(
            sellersList[_sellerAddress].isExist,
            "Seller with this wallet does not exists! "
        );

        require(
            sellersList[_sellerAddress].sellerProducts[_productID].isExist,
            "ProductID in the seller does not exists! "
        );
        //check whether the product exists
        //return the price
        return sellersList[_sellerAddress].sellerProducts[_productID].review;
    }

    function viewTransactions_ProductID(
        address _buyerAddress,
        uint256 _txnID
    ) public view returns (uint256) {
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );

        require(
            buyersList[_buyerAddress].txnMade[_txnID].isExist,
            "Txn ID in the seller does not exists! "
        );
        //check whether the product exists
        //return the price
        return buyersList[_buyerAddress].txnMade[_txnID].purchasedProductID;
    }

    function viewTransactions_Reviewed(
        address _buyerAddress,
        uint256 _txnID
    ) public view returns (bool) {
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );

        require(
            buyersList[_buyerAddress].txnMade[_txnID].isExist,
            "Txn ID in the seller does not exists! "
        );
        //check whether the product exists
        //return the price
        return buyersList[_buyerAddress].txnMade[_txnID].reviewed;
    }

    function viewTransactions_SellerID(
        address _buyerAddress,
        uint256 _txnID
    ) public view returns (uint256) {
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );

        require(
            buyersList[_buyerAddress].txnMade[_txnID].isExist,
            "Txn ID in the seller does not exists! "
        );
        //check whether the product exists
        //return the price

        address sellerAddress = buyersList[_buyerAddress]
            .txnMade[_txnID]
            .sellerAddress;

        uint256 sellerID = sellersList[sellerAddress].sellerID;

        return sellerID;
    }

    function viewTransactions_SellerAddress(
        address _buyerAddress,
        uint256 _txnID
    ) public view returns (address sellerAddress) {
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );

        require(
            buyersList[_buyerAddress].txnMade[_txnID].isExist,
            "Txn ID in the seller does not exists! "
        );
        //check whether the product exists
        //return the price

        sellerAddress = buyersList[_buyerAddress]
            .txnMade[_txnID]
            .sellerAddress;

        return sellerAddress;
    }

    function retrieveSellerAddress(
        uint256 sellerID
    ) public view returns (address sellerAddress){
        return sellersListByID[sellerID];
    }


}
