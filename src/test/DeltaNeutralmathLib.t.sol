pragma solidity >=0.8.13;

import "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";
import {DeltaNeutralMetadata} from "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";
import "../../lib/forge-std/src/Test.sol";

contract DeltaNeutralMathLibTest is Test {
    using DeltaNeutralMathLib for DeltaNeutralMetadata;
    
    function setUp() public {

    }

    function test_getDesiredAdjustment(
        uint128 _longEquityValue,
        uint128 _longLoanValue,
        uint128 _shortEquityValue,
        uint128 _shortLoanValue,
        uint128 _harvestValue,
        uint128 _leverageValue
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );

        data.getDesiredAdjustment();
    }

    function test_getLongEquityAdd(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.getLongEquityAdd(desiredAdjustment);        
    }

    function test_getShortEquityAdd(
        uint128 _longEquityValue,
        uint128 _longLoanValue,
        uint128 _shortEquityValue,
        uint128 _shortLoanValue,
        uint128 _harvestValue,
        uint128 _leverageValue,
        uint128 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );
        data.getShortEquityAdd(uint256(desiredAdjustment));
    }

    function test_getShortLoanAdd(
        uint64 _longEquityValue,
        uint64 _longLoanValue,
        uint64 _shortEquityValue,
        uint64 _shortLoanValue,
        uint64 _harvestValue,
        uint64 _leverageValue,
        uint64 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );
        data.getShortLoanAdd(uint256(desiredAdjustment));
    }

    function test_getLongLoanAdd(
        uint128 _longEquityValue,
        uint128 _longLoanValue,
        uint128 _shortEquityValue,
        uint128 _shortLoanValue,
        uint128 _harvestValue,
        uint128 _leverageValue,
        uint128 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );
        data.getLongLoanAdd(uint256(desiredAdjustment));
    }

    function test_longEquityRebalanceTarget(
        uint128 _longEquityValue,
        uint128 _longLoanValue,
        uint128 _shortEquityValue,
        uint128 _shortLoanValue,
        uint128 _harvestValue,
        uint128 _leverageValue,
        uint128 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );
        data.longEquityRebalanceTarget(uint256(desiredAdjustment));
    }

    function test_shortEquityRebalanceTarget(
        uint128 _longEquityValue,
        uint128 _longLoanValue,
        uint128 _shortEquityValue,
        uint128 _shortLoanValue,
        uint128 _harvestValue,
        uint128 _leverageValue,
        uint128 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );
        data.shortEquityRebalanceTarget(uint256(desiredAdjustment));
    }

    function test_shortLoanRebalanceTarget(
        uint128 _longEquityValue,
        uint128 _longLoanValue,
        uint128 _shortEquityValue,
        uint128 _shortLoanValue,
        uint128 _harvestValue,
        uint128 _leverageValue,
        uint128 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );
        data.shortLoanRebalanceTarget(uint256(desiredAdjustment));
    }

    function test_longLoanRebalanceTarget(
        uint128 _longEquityValue,
        uint128 _longLoanValue,
        uint128 _shortEquityValue,
        uint128 _shortLoanValue,
        uint128 _harvestValue,
        uint128 _leverageValue,
        uint128 desiredAdjustment
    ) public pure {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            uint256(_longEquityValue),
            uint256(_longLoanValue),
            uint256(_shortEquityValue),
            uint256(_shortLoanValue),
            uint256(_harvestValue),
            uint256(_leverageValue)
        );
        data.longLoanRebalanceTarget(uint256(desiredAdjustment));
    }
}