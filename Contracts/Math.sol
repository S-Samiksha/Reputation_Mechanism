// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Math
 * @dev For the mathematical functions required in the project
 */

import "../node_modules/solady/src/utils/FixedPointMathLib.sol";
using FixedPointMathLib for uint256;
using FixedPointMathLib for int256;


contract Math {
    /**
     * @dev basic mathematical functions
     * All denoted in terms of wad (input and output)
     */
    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a.mulWad(b);
        return c;
    }

    function pow0(uint256 a1, uint256 b1) public pure returns (uint256 c) {
        //internally convert a and b to int256
        int256 a = int256(a1);
        int256 b = int256(b1);
        c = uint256(a.powWad(b));
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a.divWad(b);
        return c;
    }

    function sqrt(uint256 a) public pure returns (uint256 c) {
        c = a.sqrtWad();
        return c;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = uint256(a.rawAdd(b));
        require(c >= uint256(a));
        return c;
    }

    // Follow safemath coding structure
    function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a.rawSub(b);
        return c;
    }

    function lorn(uint256 a) public pure returns (uint256 c) {
        //internally convert
        int256 a_int = int256(a);
        c = uint256(a_int.lnWad());
        return c;
    }

    /**
     * Inputs are in normal Integer Value
     * Outputs are in wad
     */
    function sigmoidalFunc(
        uint256 x,
        uint256 a,
        uint256 b,
        uint256 c
    ) public pure returns (uint256 rep) {

        //overflow 
        if (x>1000000000*10**18){
            x=1000000000*10**18;
        }
        //check the 0 condition
        if (x == b) {
            rep = a * (10 ** 18);
            return rep;
        }

        //convert to fixedpointmathlib format
        // x = x * (10 ** 18);
        // uint256 a = a_int * (10 ** 18);
        // uint256 b = b_int * (10 ** 18);
        // uint256 c = c_int * (10 ** 18);

        //if x-b is more than 0 do the normal division
        if (x > b) {
            //1. calculate (x-b) then abs then power
            uint256 temp1 = pow0(sub(x, b), 2 * (10 ** 18));

            //2. calculate add c then sqrt
            uint256 temp2 = sqrt(uint256(add(temp1, c)));

            uint256 temp3 = div(uint256(sub(x, b)), temp2);
            uint256 temp4 = add(temp3, 1 * (10 ** 18));
            rep = mul(temp4, a);
            return rep;
        } else if (x < b) {
            //1. calculate (x-b) then abs then power
            uint256 temp1 = pow0(sub(b, x), 2 * (10 ** 18));

            //2. calculate add c then sqrt
            uint256 temp2 = sqrt(uint256(add(temp1, c)));

            uint256 temp3 = div(uint256(sub(b, x)), temp2);
            uint256 temp4 = mul(temp3, a);
            rep = sub(a, temp4);
            return rep;
        }
    }

    function decay(
        uint256 timepassed,
        uint256 oldX,
        uint256 BETA_1
    ) public pure returns (uint256 w) {
        //Assumes timepassed is in wad
        w = mul(pow0(div(BETA_1, 100 * (10 ** 18)), timepassed), oldX);
    }

    function deltaT(
        uint256 delta_T,
        uint256 xold,
        uint256 b,
        uint256 beta2
    ) public pure returns (uint256 w1) {
        //by default b_int is 12

        //check the 0 condition
        if (delta_T == b) {
            w1 = 0 * (10 ** 18);
            return w1;
        }

        //convert to fixedpointmathlib format
        // delta_T = delta_T * (10 ** 18);
        // uint256 xold = xold_int * (10 ** 18);
        // uint256 b = b_int * (10 ** 18);
        // uint256 beta2 = beta2_int * (10 ** 18);

        if (delta_T > b) {
            //1. calculate (x-b) then abs then power
            uint256 temp1 = pow0(sub(delta_T, b), 2 * (10 ** 18));

            //2. calculate add c then sqrt
            uint256 temp2 = sqrt(uint256(add(temp1, beta2)));

            uint256 temp3 = div(uint256(sub(delta_T, b)), temp2);
            w1 = mul(temp3, xold);
            return w1;
        } else if (b > delta_T) {
            //1. calculate (x-b) then abs then power
            uint256 temp1 = pow0(sub(b, delta_T), 2 * (10 ** 18));

            //2. calculate add c then sqrt
            uint256 temp2 = sqrt(uint256(add(temp1, beta2)));

            uint256 temp3 = div(sub(b, delta_T), temp2);
            w1 = mul(temp3, xold);
            return w1;
        }
    }

    function lnPrice(
        uint256 price,
        uint256 xold
    ) public pure returns (uint256 w2) {
        uint256 priceWad = div(price, 10 ** 18); //convert to decimal places
        // uint256 xold = xold_int * (10 ** 18);
        priceWad = add(priceWad, 1 * (10 ** 18));
        w2 = lorn(priceWad);
        w2 = mul(w2, xold);
        return w2;
    }

    function ratingDiff(
        uint256 betas_int,
        uint256 rincoming_int,
        uint256 raverage_int,
        uint256 repscore_int,
        uint256 xold_int
    ) public pure returns (uint256 w1) {
        if (rincoming_int > raverage_int) {
            uint256 Rdiff = sub(rincoming_int, raverage_int);
            uint256 temp1 = div(betas_int, Rdiff);
            uint256 temp2 = div(
                mul(temp1, repscore_int),
                1000 * (10 ** 18)
            );
            w1 = mul(temp2, xold_int);
            return w1;
        } else if (rincoming_int < raverage_int) {
            uint256 Rdiff = sub(raverage_int, rincoming_int);
            uint256 temp1 = div(betas_int, Rdiff);
            uint256 temp2 = div(
                mul(temp1, repscore_int),
                1000 * (10 ** 18)
            );
            w1 = mul(temp2, xold_int);
            return w1;
        } else {
            return 0;
        }
    }

    function calculateReward(
        uint256 repscore,
        uint256 price
    ) public pure returns (uint256 reward) {
        uint256 priceWad = div(price, 10 ** 18); //convert to decimal places
        // 10% of the price multiplied by the reputation score
        reward = div(mul(priceWad, repscore), 10 * 10 ** 18);
        return reward;
    }

    function calculateX_Seller(
        uint256 oldX,
        uint256 rep_score,
        uint256 rincoming,
        uint256 raverage,
        uint256 BETA_S
    ) public pure returns (uint256 newX) {
        //when storing the oldX, rep_score --> stored in Wad format
        //must convert the rincoming, raverage and betas into wad format
        if (rincoming>raverage){
        newX = add(
            oldX,
            ratingDiff(
                div(BETA_S * (10 ** 18), 10*(10 ** 18)), //obtaining 0.1 by doing 1/10
                rincoming * (10 ** 18),
                raverage * (10 ** 18),
                rep_score,
                oldX
            )
        );}
        else{
            newX = sub(
            oldX,
            ratingDiff(
                div(BETA_S * (10 ** 18), 10*(10 ** 18)),
                rincoming * (10 ** 18),
                raverage * (10 ** 18),
                rep_score,
                oldX
            )
        );
        }
    }

    function sigmoidal_calc(
        uint256 A_VALUE,
        uint256 B_VALUE,
        uint256 C_VALUE,
        uint256 newX
    ) public pure returns (uint256 rep) {
        rep = sigmoidalFunc(
            newX,
            A_VALUE * (10 ** 18),
            B_VALUE * (10 ** 18),
            C_VALUE * (10 ** 18)
        );
    }

    function calculateX_Buyer(
        uint256 oldX,
        uint256 timeFromInActivity,
        uint256 price,
        uint256 timeFromLastReview,
        uint256 BETA_1,
        uint256 BETA_2,
        uint256 b
    ) public pure returns (uint256 newX) {
        //when storing the oldX, rep_score --> stored in Wad format
        //must convert the timepassed, deltaT, Beta1, Beta2, b and price into wad format
        if (timeFromLastReview >= b) {
            uint256 temp = add(
                decay(
                    timeFromInActivity * (10 ** 18),
                    oldX,
                    BETA_1 * (10 ** 18)
                ),
                deltaT(
                    timeFromLastReview * (10 ** 18),
                    oldX,
                    b * (10 ** 18),
                    BETA_2 * (10 ** 18)
                )
            );
            newX = add(temp, lnPrice(price, oldX));
        } else {
            uint256 temp = add(
                decay(
                    timeFromInActivity * (10 ** 18),
                    oldX,
                    BETA_1 * (10 ** 18)
                ),
                lnPrice(price, oldX)
            );
            newX = sub(
                temp,
                deltaT(
                    timeFromLastReview * (10 ** 18),
                    oldX,
                    b * (10 ** 18),
                    BETA_2 * (10 ** 18)
                )
            );
        }
    }
}
