// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Math
 * @dev For the mathematical functions required in the project
 */

import "https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol";
using FixedPointMathLib for uint256;
using FixedPointMathLib for int256;

contract Math {
    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a.mulWad(b);
        return c;
    }

    function pow0(int256 a, int256 b) public pure returns (int256 c) {
        c = a.powWad(b);
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a.divWad(b);
        return c;
    }

    function sqrt(uint256 a) public pure returns (uint256 c) {
        c = a.sqrtWad();
        return c;
    }

    function add(int256 a, int256 b) public pure returns (int256 c) {
        c = a.rawAdd(b);
        return c;
    }

    //TODO: the overflow condition check
    // Follow safemath coding structure
    function sub(int256 a, int256 b) public pure returns (int256 c) {
        c = a.rawSub(b);
        return c;
    }

    function abs2(int256 a) public pure returns (uint256 c) {
        c = a.abs();
        return c;
    }

    function muldiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) public pure returns (uint256 c) {
        c = x.fullMulDivUp(y, d);
        return c;
    }

    function sigmoidalFunc(
        int256 x,
        uint256 a_int,
        int256 b_int,
        int256 c_int
    ) public pure returns (uint256 rep) {
        //check the 0 condition
        if (x == b_int) {
            rep = a_int * (10 ** 18);
            return rep;
        }

        //convert to fixedpointmathlib format
        x = x * (10 ** 18);
        uint256 a = a_int * (10 ** 18);
        int256 b = b_int * (10 ** 18);
        int256 c = c_int * (10 ** 18);

        //1. calculate (x-b) then abs then power
        int256 temp1 = pow0(int256(abs2(sub(x, b))), 2 * (10 ** 18));

        //2. calculate add c then sqrt
        uint256 temp2 = sqrt(uint256(add(temp1, c)));

        //3. if x-b is more than 0 do the normal division
        if (x > b) {
            uint256 temp3 = div(uint256(sub(x, b)), temp2);
            uint256 temp4 = uint256(add(int256(temp3), 1 * (10 ** 18)));
            uint256 temp5 = mul(temp4, a);
            rep = temp5;
            return rep;
        } else if (x < b) {
            uint256 temp3 = div(uint256(abs2(sub(x, b))), temp2);
            uint256 temp4 = mul(temp3, a);
            uint256 temp5 = uint256(sub(int256(a), int256(temp4)));
            rep = temp5;
            return rep;
        }
    }

    function deltaT(
        int256 delta_T,
        uint256 xold_int,
        int256 b_int,
        int256 beta2_int
    ) public pure returns (uint256 w1) {
        //by default b_int is 12

        //check the 0 condition
        if (delta_T == b_int) {
            w1 = 0 * (10 ** 18);
            return w1;
        }

        //convert to fixedpointmathlib format
        delta_T = delta_T * (10 ** 18);
        uint256 xold = xold_int * (10 ** 18);
        int256 b = b_int * (10 ** 18);
        int256 beta2 = beta2_int * (10 ** 18);

        if (delta_T > b) {
            //1. calculate (x-b) then abs then power
            int256 temp1 = pow0(int256(abs2(sub(delta_T, b))), 2 * (10 ** 18));

            //2. calculate add c then sqrt
            uint256 temp2 = sqrt(uint256(add(temp1, beta2)));

            uint256 temp3 = div(uint256(sub(delta_T, b)), temp2);
            w1 = mul(temp3, xold);
            return w1;
        } else if (b > delta_T) {
            //1. calculate (x-b) then abs then power
            int256 temp1 = pow0(int256(abs2(sub(b, delta_T))), 2 * (10 ** 18));

            //2. calculate add c then sqrt
            uint256 temp2 = sqrt(uint256(add(temp1, beta2)));

            uint256 temp3 = div(uint256(abs2(sub(b, delta_T))), temp2);
            w1 = mul(temp3, xold);
            return w1;
        }
    }

    function lnPrice(
        uint256 price,
        uint256 xold_int
    ) public pure returns (uint256 w2) {
        int256 priceWad = int256(div(price, 10 ** 18)); //convert to wad and obtain in decimal places
        uint256 xold = xold_int * (10 ** 18);
        priceWad = add(priceWad, 1 * (10 ** 18));
        w2 = uint256(priceWad.lnWad());
        w2 = mul(w2, xold);
        return w2;
    }

    function ratingDiff(
        uint256 betas_int,
        int256 rincoming_int,
        int256 raverage_int,
        uint256 repscore_int,
        uint256 xold_int
    ) public pure returns (uint256 w1) {
        if (rincoming_int > raverage_int) {
            uint256 Rdiff = uint256(
                sub(rincoming_int * (10 ** 18), raverage_int * (10 ** 18))
            );
            int256 temp1 = int256(div(betas_int * (10 ** 18), Rdiff));
            uint256 temp2 = div(
                mul(
                    uint256(add(temp1, 1 * (10 ** 18))),
                    repscore_int * (10 ** 18)
                ),
                1000 * (10 ** 18)
            );
            w1 = mul(temp2, xold_int * (10 ** 18));
            return w1;
        } else if (rincoming_int < raverage_int) {
            uint256 Rdiff = uint256(
                sub(raverage_int * (10 ** 18), rincoming_int * (10 ** 18))
            );
            int256 temp1 = int256(div(betas_int * (10 ** 18), Rdiff));
            uint256 temp2 = div(
                mul(
                    uint256(add(temp1, 1 * (10 ** 18))),
                    repscore_int * (10 ** 18)
                ),
                1000 * (10 ** 18)
            );
            w1 = mul(temp2, xold_int * (10 ** 18));
            return w1;
        } else {
            return 0;
        }
    }
}
