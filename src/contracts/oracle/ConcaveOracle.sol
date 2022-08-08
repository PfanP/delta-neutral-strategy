pragma solidity ^0.8.13;

import '../../interfaces/oracle/IBaseOracle.sol';
import './UsingBaseOracle.sol';
import './Governable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract ConcaveOracle is IBaseOracle, Governable {
    using SafeMath for uint;

    mapping(address => uint) public primarySourceCount; // Mapping from token to number of sources
    mapping(address => mapping(uint => IBaseOracle)) public primarySources; // Mapping from token to (mapping from index to oracle source)


    function initialize() public initializer {
      __Governable__init();
    }

    function getETHPx(address token) external view returns (uint) {

    }

    function getPrice(address token, address unitToken) external view returns (uint, uint) {

    }
}