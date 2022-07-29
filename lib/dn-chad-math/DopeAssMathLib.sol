// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library DopeAssMathLib {

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function average(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x & y) + ((x ^ y) >> 1); // (x + y) / 2 can overflow.
    }

    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        // 512-bit multiply [z1 z0] = a * b Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is 
        // stored in two 256 variables such that product = z1 * 2**256 + z0

        uint256 z0; // Least significant 256 bits of the product
        uint256 z1; // Most significant 256 bits of the product

        assembly {
            let mm := mulmod(x, y, not(0))
            z0 := mul(x, y)
            z1 := sub(sub(mm, z0), lt(mm, z0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (z1 == 0) {
            
            assembly {
                z := div(z0, denominator) // not sure how this is cheaper than
            }

            return z;
        }

        assembly {
            // Make sure the result is less than 2**256. Also prevents denominator == 0
            if iszero(gt(denominator, z1)) { revert(0, 0) }
            
            let twos := and(sub(0, denominator), denominator)
            
            denominator := div(denominator, twos)

            // Make division exact by subtracting the remainder from [z1 z0]
            // Compute remainder using mulmod
            let remainder := mulmod(x, y, denominator)

            z1 := sub(z1, gt(remainder, z0))
            z0 := add(div(sub(z0, remainder), twos), mul(z1, add(div(sub(0, twos), twos), 1)))
            
            let inv := xor(mul(3, denominator), 2)

            inv := mul(inv, sub(2, mul(denominator, inv))) // inv mod 2^8
            inv := mul(inv, sub(2, mul(denominator, inv))) // inv mod 2^16
            inv := mul(inv, sub(2, mul(denominator, inv))) // inv mod 2^32
            inv := mul(inv, sub(2, mul(denominator, inv))) // inv mod 2^64
            inv := mul(inv, sub(2, mul(denominator, inv))) // inv mod 2^128
            inv := mul(inv, sub(2, mul(denominator, inv))) // inv mod 2^256

            z := mul(z0, inv)
        }
    }

    function mulDivDownDope(
        uint256 x, 
        uint256 y, 
        uint256 denominator
    ) internal pure returns (uint256 z) {

        


    }

    /////////////////////////////////////////////////////////
    // WAD MATH
    /////////////////////////////////////////////////////////

    uint256 internal constant WAD = 1e18;

    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mulDivDown(x, y, WAD);
    }

    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mulDivDown(x, WAD, y);
    }
}
