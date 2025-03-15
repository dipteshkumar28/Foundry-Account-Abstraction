// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MinimalAccount} from "../src/Ethereum/MinimalAccount.sol";

contract DeployMinimal is Script {
    function run() public {}

    function deployminimal() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getconfig();

        vm.startBroadcast(config.account);
        MinimalAccount minimalaccount = new MinimalAccount(config.entryPoint);
        minimalaccount.transferOwnership(config.account);
        vm.stopBroadcast();

        return (helperconfig, minimalaccount);
    }
}
