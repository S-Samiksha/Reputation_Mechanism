// SPDX-License-Identifier: MIT

//Get funds from users 
//Withdraw funds
//Set a minimum value in USD
/*
Transactions - Function Call:
Nonce: tx count for the account 
Gas Price: price per unit of gas (in wei)
Gas Limit: max gas that this tx can use
To: Address that the tx is sent to 
Value: amount of wei to send 
Data: What to send to the To address
v,r,s: components of the tx signature
*/

/*
Smart contracts are unable to connect with external systems, data feeds, APIs, 
existing payment systems or any other off-chain resources on their own.

Blockchain is meant to be deterministic and have to reach a consensus. 
However if you are using an API, you may have different results and therefore a different consensus. 

Blockchain oracle: any device that interacts with the off-chain world to provide external data or computation to smart contracts. 

Chainlink is a decentralized oracle network for bring data from the real world. 

Chainlink keepers 

End-to-end reliability is the promise of the smart contracts

*/


pragma solidity ^0.8.21; 
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


error FundMe__NotOwner();


contract FundMe {

    using PriceConverter for uint256; 

    mapping(address => uint256) public addressToAmountFunded; 
    
    //keep track of people who gave the money 
    address[] public funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;
    uint256 public constant MINIMUM_USD = 1 * 1e18;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    

    function fund() public payable{
        //want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract
        // require(msg.value>=1e18,"Didn't send enough");  //1e18 == 1* 10**18 == value of one ETH in wei

        //what is reverting 
        // undo any action before, and send remaining gas back

        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        // msg sender is whoever calls the fund function
        funders.push(msg.sender);


     }
    
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; //do the rest of the function
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        /*
        three different ways to transfer the funds:
        1. Transfer
        msg.sender = address
        payable(msg.sender) = payable address



        
        */
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }






}