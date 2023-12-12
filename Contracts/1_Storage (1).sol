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

    function muldiv(uint256 x, uint256 y, uint256 d) public pure returns (uint256 c){
        c = x.fullMulDivUp(y, d);
        return c;
    }

    function sigmoidalFunc(int256 x) public pure returns (uint256 rep){
        if (x==500){
            rep =  50 * (10**18);
        }
        x = x * (10**18);
        uint256 a = 50 * (10**18);
        int256 b = 500 * (10**18);
        int256 c = 35000 * (10**18);
        //1. calculate (x-b) then abs then power 
        int256 temp1 = pow0(int256(abs2(sub(x, b))), 2 * (10**18));
        //2. calculate add c then sqrt
        uint256 temp2 = sqrt(uint256(add(temp1, c)));
        //3. if x-b is more than 0 do the normal division
        if (sub(x,b)>0){
            uint256 temp3 = div(uint256(sub(x,b)), temp2);
            uint256 temp4 = uint256(add(int256(temp3), 1* (10**18)));
            uint256 temp5 = mul(temp4, a);
            rep = temp5;
        }
        else if (sub(x,b)<0){
            uint256 temp3 = div(uint256(abs2(sub(x,b))), temp2);
            uint256 temp4 = mul(temp3, a);
            uint256 temp5 = uint256(sub(int256(a), int256(temp4)));
            rep = temp5;
        }
        

        

    }

}