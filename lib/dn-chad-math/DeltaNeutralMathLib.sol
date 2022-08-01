// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./DopeAssMathLib.sol";

struct DeltaNeutralMetadata {
    uint256 longEquityValue;
    uint256 longLoanValue;
    uint256 shortEquityValue;
    uint256 shortLoanValue;
    uint256 harvestValue;
    uint256 leverageValue;
}

library DeltaNeutralMathLib {

    using DopeAssMathLib for uint256;

    function getDesiredAdjustment(
        DeltaNeutralMetadata memory data
    ) internal pure returns (uint256 desiredAdjustment) {
        
        //           / lEv + sEv + hV \
        //    daf = ( ---------------- ) 
        //           \     1 + lV     /
        return (data.longEquityValue + data.shortEquityValue + data.harvestValue).divWad(1e18 + data.leverageValue);
    }
    
    // Harvest Specific Math

    function getLongEquityAdd(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 longEquityAdd) {
        
        //    /
        //   / if    (lEv > daf)     lEa = 0 
        //  /                                /
        // {                                / if       (daf - lEv > hV)    lEa = hV
        //  \  else                  lEa = {
        //   \                              \ else                         lEa = daf - lEv
        //    \                              \
        return data.longEquityValue > desiredAdjustment ?
            0 : 
            (
                desiredAdjustment - data.longEquityValue > data.harvestValue ? 
                    data.harvestValue : 
                    desiredAdjustment - data.longEquityValue
            );
    }

    function getShortEquityAdd(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 shortEquityAdd) {

        //  sLa = lV * dA
        uint256 scaledLeverageAdjustment = data.leverageValue.mulWad(desiredAdjustment);

        //    /
        //   / if    (sEv > sLa)     sEa = 0 
        //  /                                /
        // {                                / if       (sLa - sEv > hV)    sEa = hV
        //  \  else                  sEa = {
        //   \                              \ else                         sEa = sLa - sEv
        //    \                              \
        return data.shortEquityValue > scaledLeverageAdjustment ?
            0 : 
            (
                scaledLeverageAdjustment - data.shortEquityValue > data.harvestValue ? 
                    data.harvestValue : 
                    scaledLeverageAdjustment - data.shortEquityValue
            );
    }

    function getShortLoanAdd(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 shortLoanAdd) {

        uint256 leverageValueSquared = data.leverageValue.mulWad(data.leverageValue);

        return data.shortLoanValue < desiredAdjustment.mulWad(leverageValueSquared) ?
            desiredAdjustment.mulWad(leverageValueSquared) - data.shortLoanValue :
            (
                data.shortLoanValue < data.shortEquityValue.mulWad(data.leverageValue) ? 
                    data.shortEquityValue.mulWad(leverageValueSquared) - data.shortLoanValue : 
                    0
            );
    
    }

    function getLongLoanAdd(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 longLoanAdd) {

        return data.longLoanValue < desiredAdjustment.mulWad(data.leverageValue) ?
            desiredAdjustment.mulWad(data.leverageValue) - data.longLoanValue :
            (
                data.longLoanValue < data.longEquityValue.mulWad(data.leverageValue) ? 
                    data.longEquityValue.mulWad(data.leverageValue) - data.longLoanValue : 
                    0
            );
    }

    //////////////////////////////////////////////
    // Rebalancing Math
    //////////////////////////////////////////////

    function longEquityRebalance(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 longEquityAdd, bool addToPosition) {
        // Boolean - True: Add to the position | False: Take from the position
        return data.longEquityValue < desiredAdjustment ?
            (desiredAdjustment - data.longEquityValue, true): 
        (data.longEquityValue - desiredAdjustment, false);
    }

    function shortEquityRebalance(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 shortEquityAdd, bool addToPosition) {
        // Boolean - True: Add to the position | False: Take from the position
        uint256 adjustmentTimesLeverage = desiredAdjustment.mulWad(data.leverageValue);

        return data.shortEquityValue < adjustmentTimesLeverage ?
            (adjustmentTimesLeverage - data.shortEquityValue, true): 
        (data.shortEquityValue - adjustmentTimesLeverage, false);
    }

    function shortLoanRebalance(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 shortLoanAdd, bool addToPosition) {
        // Boolean - True: Add to the position | False: Take from the position
        uint256 leverageValueSquared = data.leverageValue.mulWad(data.leverageValue);
        uint256 adjustmentTimesLeverageSquared = desiredAdjustment.mulWad(leverageValueSquared);

        return data.shortLoanValue < adjustmentTimesLeverageSquared ?
            (adjustmentTimesLeverageSquared - data.shortLoanValue, true): 
            (data.shortLoanValue - adjustmentTimesLeverageSquared, false);
    }

    function longLoanRebalance(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 longLoanAdd, bool addToPosition) {
        // Boolean - True: Add to the position | False: Take from the position
        uint256 adjustmentTimesLeverage = desiredAdjustment.mulWad(data.leverageValue);

        return data.longLoanValue < adjustmentTimesLeverage ?
            (adjustmentTimesLeverage - data.longLoanValue, true): 
        (data.longLoanValue - adjustmentTimesLeverage, false);
    }

}