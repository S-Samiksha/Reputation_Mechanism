// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Store {
    uint256 private totalSellers = 0;
    uint256 private totalBuyers = 0;

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
    }

    struct Transaction {
        uint256 txnID;
        uint256 timeStamp;
        Product purchasedProduct;
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
        uint256 buyerID
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

    function createSeller(string memory _sellerName) public {
        require(
            !sellersList[msg.sender].isExist,
            "Seller with this wallet already exists! "
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
        emit createSellerEvent(
            newSeller.sellerName,
            newSeller.sellerAddress,
            newSeller.sellerID
        );
    }

    function createBuyer(string memory _buyerName) public {
        require(
            !buyersList[msg.sender].isExist,
            "Buyer with this wallet already exists! "
        );
        Buyer storage newBuyer = buyersList[msg.sender]; //get the object
        //set the variables
        newBuyer.buyerAddress = msg.sender;
        newBuyer.buyerName = _buyerName;
        newBuyer.buyerID = ++totalBuyers;
        newBuyer.isExist = true;
        newBuyer.numOfReviewsGiven = 0;
        newBuyer.numOfTxn = 0;

        emit createBuyerEvent(
            newBuyer.buyerName,
            newBuyer.buyerAddress,
            newBuyer.buyerID
        );
    }

    function uploadProduct(string memory _productName, uint256 price) public {
        //only the currently connected wallet + must be registered seller can create products
        require(
            sellersList[msg.sender].isExist,
            "Seller with this wallet does not exists! "
        );

        Seller storage currentSeller = sellersList[msg.sender]; //TODO: why is it storage?

        Product storage newProduct = currentSeller.sellerProducts[
            currentSeller.totalProducts
        ];

        newProduct.productID = currentSeller.totalProducts;
        newProduct.productName = _productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.productPrice = price;
        newProduct.totalSold = 0;
        newProduct.isExist = true;

        currentSeller.sellerProducts[currentSeller.totalProducts] = newProduct;
        currentSeller.totalProducts++;

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
        address payable sellerAddress
    ) public payable {
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

        //TODO: figure out the gas txn fee

        (bool callSuccess, ) = sellerAddress.call{value: msg.value}("");
        require(callSuccess, "Failed to send ether");

        uint256 txnID = buyersList[msg.sender].numOfTxn;

        Transaction storage newTxn = buyersList[msg.sender].txnMade[txnID];
        newTxn.txnID = txnID;
        newTxn.timeStamp = block.timestamp;
        newTxn.purchasedProduct = sellersList[sellerAddress].sellerProducts[
            productID
        ]; //push the sellers product into the transaction list
        newTxn.reviewed = false;
        newTxn.isExist = true;
        buyersList[msg.sender].txnMade[txnID] = newTxn;
        buyersList[msg.sender].numOfTxn++;

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

    function buyerReview(uint256 buyerRating, uint256 txnID) public {
        require(buyersList[msg.sender].isExist, "This buyer does not exist!");

        require(
            buyersList[msg.sender].txnMade[txnID].isExist,
            "Buyer does not have this transaction ID"
        );

        address sellerAddress = buyersList[msg.sender]
            .txnMade[txnID]
            .purchasedProduct
            .sellerAddress;
        uint256 productID = buyersList[msg.sender]
            .txnMade[txnID]
            .purchasedProduct
            .productID;
        sellersList[sellerAddress].sellerProducts[productID].review =
            ((buyersList[msg.sender].txnMade[txnID].purchasedProduct.review *
                buyersList[msg.sender]
                    .txnMade[txnID]
                    .purchasedProduct
                    .numOfReviewsGiven) + buyerRating) /
            (buyersList[msg.sender]
                .txnMade[txnID]
                .purchasedProduct
                .numOfReviewsGiven + 1);

        buyersList[msg.sender]
            .txnMade[txnID]
            .purchasedProduct
            .numOfReviewsGiven++;
    }

    /* View and Pure Functions */

    function retrieveTotalBuyers() public view returns (uint256) {
        return totalBuyers;
    }

    function retrieveTotalSellers() public view returns (uint256) {
        return totalSellers;
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
            "Seller with this wallet does not exists! "
        );
        //return the price
        return
            sellersList[_sellerAddress].sellerProducts[_productID].productPrice;
    }

    function viewProductSold(
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
            "ProductID in the seller does not exists! "
        );
        //return the price
        return sellersList[_sellerAddress].sellerProducts[_productID].totalSold;
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

    function viewTransactions(
        address _buyerAddress,
        uint256 _txnID
    ) public view returns (uint256) {
        require(
            buyersList[_buyerAddress].isExist,
            "Seller with this wallet does not exists! "
        );

        require(
            buyersList[_buyerAddress].txnMade[_txnID].isExist,
            "Txn ID in the seller does not exists! "
        );
        //check whether the product exists
        //return the price
        return
            buyersList[_buyerAddress]
                .txnMade[_txnID]
                .purchasedProduct
                .productID;
    }
}
