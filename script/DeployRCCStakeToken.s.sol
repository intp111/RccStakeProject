//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import {RCCStakeToken} from "../src/RCCStakeToken.sol";

contract DeployRCCStakeToken is Script {
    RCCStakeToken rccStakeToken;

    function run() external returns (RCCStakeToken) {
        vm.startBroadcast();
        rccStakeToken = new RCCStakeToken();
        vm.stopBroadcast();
        return rccStakeToken;
    }
}
