// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Math.sol";
import "hardhat/console.sol";

contract Store {
    uint256 private totalSellers = 0;
    uint256 private totalBuyers = 0;
    uint256 private immutable A_VALUE_S = 50;
    uint256 private immutable B_VALUE_S = 300;
    uint256 private immutable C_VALUE_S = 900;
    uint256 private immutable BETA_S = 1;
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
        bool isExist; //flag to determin whether the product exists TODO: figure out a better way
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
        bool isExist;
    }

    struct Seller {
        address sellerAddress;
        string sellerName;
        uint256 sellerID;
        bool isExist; //flag to determine whether the Seller exists TODO: find a better way
        mapping(uint256 => Product) sellerProducts; //using the productID to obtain the product ; TODO: can we use a string instead?
        uint256 totalProducts;
        uint256 totalRevenue;
        uint256 numOfSales;
    }

    struct Buyer {
        address buyerAddress;
        string buyerName;
        uint256 buyerID; //TODO: figure out the difference between uint and uint256
        bool isExist; //flag to determine whether the buyer exists TODO: figure out a better way
        mapping(uint256 => Transaction) txnMade;
        uint256 numOfTxn;
        uint256 numOfReviewsGiven;
        uint256 lastReviewTime;
        uint256 repScore;
        uint256 X_Value;
    }

    //----- Mappings -----

    //Maps user address to Seller or Buyer account structs
    // TODO: can we merge this with the object itself?
    // Mapping buyerAddress to array of Products that they bought
    // mapping(address => Product[]) public buyerPurchasedProducts;

    mapping(address => Seller) public sellersList;
    mapping(address => Buyer) public buyersList;

    //-----Events -----
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

    /* Constructor to deploy the math library */
    constructor() {
        MathLib = new Math();
        MathLibAddress = address(MathLib);
    }

    function createSeller(string memory _sellerName) public {
        require(
            !sellersList[msg.sender].isExist,
            "Seller with this wallet already exists!"
        );
        Seller storage newSeller = sellersList[msg.sender]; //get the object
        //set the variables
        newSeller.sellerAddress = msg.sender;
        newSeller.sellerName = _sellerName;
        newSeller.sellerID = ++totalSellers; //TODO: convert to wad
        newSeller.isExist = true;
        newSeller.totalProducts = 0;
        newSeller.totalRevenue = 0;
        newSeller.numOfSales = 0;

        // sellersList[msg.sender] = newSeller;
        emit createSellerEvent(
            newSeller.sellerName,
            newSeller.sellerAddress,
            newSeller.sellerID
        );

        console.log("Seller Created at:", msg.sender);
    }

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

    function uploadProduct(string memory _productName, uint256 price) public {
        //only the currently connected wallet + must be registered seller can create products
        require(
            sellersList[msg.sender].isExist,
            "Seller with this wallet does not exists!"
        );

        Seller storage currentSeller = sellersList[msg.sender]; //TODO: why is it storage?

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

    function purchaseProduct(
        uint256 productID,
        address sellerAddress
    ) public payable returns (uint256 txnID) {
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

        return txnID;
    }

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

        uint256 lastReviewTime = 0;
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

        if (lastReviewTime == 0) {
            //means the buyer has never reviewed the product before
            //add weightage of 0
            lastReviewTime = B_TOLERANCE;
        } else {
            //convert to hours
            /*
            For testing purposes, a time lapse of 1 minute is made to become 1 hour 
            60 seconds --> divide by 60 --> 1 min 
            12min is 12 hours
            13 min is 13 hours 
            */
            lastReviewTime = (block.timestamp - lastReviewTime) / 60;
        }

        //update XValue and Reputation Score of Buyers
        buyersList[msg.sender].X_Value = calculateXValue_Buyer(
            buyersList[msg.sender].X_Value,
            timepassed,
            price,
            lastReviewTime
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

    /* Calculation of reputation scores, review scores and incentive*/

    // function calculateIncentive(uint256 repscore, uint256 price) private{
    //     uint256 reward = MathLib.calculateReview(repscore, price); //this is in wei

    // }

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

    /* View and Pure Functions */

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
}
