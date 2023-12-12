// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

import  "https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol";
using FixedPointMathLib for  uint256;
using FixedPointMathLib for  int256;


contract Storage {

    uint256 number;


    function mul(uint256 a,  uint256 b)  public  pure  returns  (uint256 c)  {
        c = a.mulWad(b);
        return c;
    }


    function pow0(int256 a,  int256 b)  public  pure  returns  (int256 c)  {
        c = a.powWad(b);
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 c){
        c = a.divWad(b);
        return c;
    }

    function sqrt(uint256 a) public pure returns (uint256 c){
        c = a.sqrtWad();
        return c;
    }
    function add(int256 a, int256 b) public pure returns (int256 c){
        c = a.rawAdd(b);
        return c;
    }
    function sub(int256 a, int256 b) public pure returns (int256 c){
        c = a.rawSub(b);
        return c;
    }
    function abs2(int256 a) public pure returns (uint256 c){
        c = a.abs();
        return c;
    }

    function sigmoidalFunc(int256 x) public pure returns (uint256 rep){
        x = x * (10**18);
        uint256 a = 50 * (10**18);
        int256 b = 500 * (10**18);
        int256 c = 35000 * (10**18);
        int256 numerator = sub(x,b);
        int256 denominatorP1 = sub(x,b);
        uint256 denominatorAsqrt = sqrt(uint256(add(pow0(60*(10**18), 2*(10**18)),c)));

        uint256 numeratorp2= mul(uint256(add(numerator, int256(denominatorAsqrt))), a);

        rep = div(numeratorp2, denominatorAsqrt);



        

    }

}