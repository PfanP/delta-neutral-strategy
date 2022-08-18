pragma solidity >=0.8.13;
import "../utils/StrategyFixture.sol";
import { Token } from "../../contracts/yearn/test/Token.sol";

contract StrategyClone is StrategyFixture {   
    Token public token;

    function setUp() public override {
        super.setUp();
    }

    function testClone() public {
        token = new Token(18);
        vault = IVault(deployVault(
            address(token),
            gov,
            rewards,
            "Test",
            "TEST",
            guardian,
            management
        ));
        strategy = Strategy(deployStrategy(address(vault)));
    }
}