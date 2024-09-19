//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RCCStakeToken is ERC20 {
    constructor() ERC20("RCCC Stake Token", "RST") {
        _mint(msg.sender, 100 ether);
    }

    function version() public pure returns (uint256) {
        return 1;
    }
}
