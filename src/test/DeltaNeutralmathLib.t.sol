pragma solidity >=0.8.13;

import "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";
import {DeltaNeutralMetadata} from "../../lib/dn-chad-math/DeltaNeutralMathLib.sol";
import "../../lib/forge-std/src/Test.sol";

contract DeltaNeutralMathLibTest is Test {
    using DeltaNeutralMathLib for DeltaNeutralMetadata;
    
    function setUp() public {

    }

    function test_getDesiredAdjustment(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
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
    ) public {
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
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.getShortEquityAdd(desiredAdjustment);
    }

    function test_getShortLoanAdd(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.getShortLoanAdd(desiredAdjustment);
    }

    function test_getLongLoanAdd(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.getLongLoanAdd(desiredAdjustment);
    }

    function test_longEquityRebalanceTarget(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.longEquityRebalanceTarget(desiredAdjustment);
    }

    function test_shortEquityRebalanceTarget(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.shortEquityRebalanceTarget(desiredAdjustment);
    }

    function test_shortLoanRebalanceTarget(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.shortLoanRebalanceTarget(desiredAdjustment);
    }

    function test_longLoanRebalanceTarget(
        uint256 _longEquityValue,
        uint256 _longLoanValue,
        uint256 _shortEquityValue,
        uint256 _shortLoanValue,
        uint256 _harvestValue,
        uint256 _leverageValue,
        uint256 desiredAdjustment
    ) public {
        DeltaNeutralMetadata memory data = DeltaNeutralMetadata(
            _longEquityValue,
            _longLoanValue,
            _shortEquityValue,
            _shortLoanValue,
            _harvestValue,
            _leverageValue
        );
        data.longLoanRebalanceTarget(desiredAdjustment);
    }
}