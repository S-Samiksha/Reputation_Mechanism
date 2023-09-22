// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract Store {
    uint256 public totalSellers = 0;
    uint256 public totalBuyers = 123;


    function retrieve() public view returns (uint256) {
        return totalBuyers;
    }

    struct Product {
        uint256 ProductID;
        string productName;
        address sellerAddress; // The product object has a sellerAddress
        uint256 productPrice; //in wei TODO: convertable to USD
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
    }

    //----- Mappings -----

    //Maps user address to Seller or Buyer account structs
    mapping(address => Seller) public sellersList;
    mapping(address => Buyer) public buyersList;

    // Mapping buyerAddress to array of Products that they bought --> TODO: can we merge this with the object itself?
    mapping(address => Product[]) public buyerPurchasedProducts;

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

        buyersList[msg.sender] = newBuyer;
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

        newProduct.ProductID = currentSeller.totalProducts;
        newProduct.productName = _productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.productPrice = price;
        newProduct.isExist = true;
        currentSeller.sellerProducts[currentSeller.totalProducts] = newProduct;
        currentSeller.totalProducts++;
    }

    function viewProductPrice(
        address _sellerAdd,
        uint256 _productID
    ) public view returns (uint256) {
        //check whether the seller exists
        require(
            sellersList[_sellerAdd].isExist,
            "Seller with this wallet does not exists! "
        );
        //check whether the product exists
        require(
            sellersList[_sellerAdd].sellerProducts[_productID].isExist,
            "Seller with this wallet does not exists! "
        );
        //return the price
        return sellersList[_sellerAdd].sellerProducts[_productID].productPrice;
    }

    /*
    TODO:
    purchase product 
    Leave a review 
    Split based on OODP


    */
}
