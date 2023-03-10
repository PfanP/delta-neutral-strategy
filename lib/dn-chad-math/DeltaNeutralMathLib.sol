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
    
    /////////////////////////////////////////
    ////////// Harvesting Math //////////////
    /////////////////////////////////////////

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
    ////////// Rebalancing Math //////////////////
    //////////////////////////////////////////////

    function longEquityRebalanceTarget(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 longEquityTarget) {
        return desiredAdjustment;
    }

    function shortEquityRebalanceTarget(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 shortEquityTarget) {
        return desiredAdjustment.mulWad(data.leverageValue);
    }

    function shortLoanRebalanceTarget(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 shortLoanTarget) {
        return desiredAdjustment.mulWad(data.leverageValue.mulWad(data.leverageValue));
    }

    function longLoanRebalanceTarget(
        DeltaNeutralMetadata memory data,
        uint256 desiredAdjustment
    ) internal pure returns (uint256 longLoanTarget) {
        return desiredAdjustment.mulWad(data.leverageValue);
    }

}
