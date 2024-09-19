//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {RCCStake} from "../src/RCCStake.sol";

contract DeployRCCStake is Script {
    function run() external returns (RCCStake) {
        vm.startBroadcast();
        RCCStake rccStake = new RCCStake();
        vm.stopBroadcast();
        return rccStake;
    }
}
