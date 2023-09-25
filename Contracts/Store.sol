// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Store {


    uint256 private totalSellers = 0;
    uint256 private totalBuyers = 0;


    //----- Structs -----

    struct Product {
        uint256 ProductID;
        string productName;
        address sellerAddress; // The product object has a sellerAddress reference 
        uint256 productPrice; //in wei 
        uint256 totalSold;
        bool isExist; //flag to determin whether the product exists TODO: figure out a better way
    }

    struct Seller {
        address sellerAddress;
        string sellerName;
        uint256 sellerID;
        bool isExist; //flag to determine whether the Seller exists TODO: find a better way
        mapping(uint256 => Product) sellerProducts; //using the productID to obtain the product ; TODO: can we use a string instead?
        uint256 totalProducts;
    }

    struct Buyer {
        address buyerAddress;
        string buyerName;
        uint256 buyerID; //TODO: figure out the difference between uint and uint256
        bool isExist; //flag to determine whether the buyer exists TODO: figure out a better way
        Product[] purchasedProducts;
    }

    //----- Mappings -----

    //Maps user address to Seller or Buyer account structs
    mapping(address => Seller) public sellersList;
    mapping(address => Buyer) public buyersList;

    // TODO: can we merge this with the object itself?
    // Mapping buyerAddress to array of Products that they bought
    // mapping(address => Product[]) public buyerPurchasedProducts;

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

        // sellersList[msg.sender] = newSeller;
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
        buyersList[msg.sender] = newBuyer; //Is this necessary 

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

        newProduct.ProductID = ++currentSeller.totalProducts;
        newProduct.productName = _productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.productPrice = price;
        newProduct.totalSold = 0;
        newProduct.isExist = true;

        currentSeller.sellerProducts[currentSeller.totalProducts] = newProduct;
    }

    


    function purchaseProduct(uint256 productID, address payable sellAddress) public payable{
        require(buyersList[msg.sender].isExist, "This buyer does not exist!");
        require(sellersList[sellAddress].sellerProducts[productID].isExist, "The Product does not exist!");
        require(msg.value==sellersList[sellAddress].sellerProducts[productID].productPrice, "Ethers not enough/too much to buy the product!");

        //TODO: figure out the gas txn fee 

        (bool callSuccess, ) = sellAddress.call{value: msg.value}("");
        require(callSuccess, "Failed to send ether");

        buyersList[msg.sender].purchasedProducts.push(sellersList[sellAddress].sellerProducts[productID]);

        sellersList[sellAddress].sellerProducts[productID].totalSold++;


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
        return sellersList[_sellerAddress].sellerProducts[_productID].productPrice;
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
            "Seller with this wallet does not exists! "
        );
        //return the price
        return sellersList[_sellerAddress].sellerProducts[_productID].totalSold;
    }

    function viewProductBought(
        address _buyerAddress,
        uint256 _txnID
    ) public view returns (uint256) {
        //check whether the seller exists
        require(
            buyersList[_buyerAddress].isExist,
            "Buyer with this wallet does not exists! "
        );
        //check whether the product exists
        //return the price
        return buyersList[_buyerAddress].purchasedProducts[_txnID].ProductID;
    }


}
