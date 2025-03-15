// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MinimalAccount} from "../src/Ethereum/MinimalAccount.sol";
import {DeployMinimal} from "../script/DeployMinimal.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    HelperConfig helperconfig;
    MinimalAccount minimalaccount;
    ERC20Mock usdc;

    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        DeployMinimal deployminimal = new DeployMinimal();
        (helperconfig, minimalaccount) = deployminimal.deployminimal();
        usdc = new ERC20Mock();
    }

    function testOwnerCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalaccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcdata = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalaccount),
            AMOUNT
        );

        vm.prank(minimalaccount.owner());

        minimalaccount.execute(dest, value, funcdata);

        assertEq(usdc.balanceOf(address(minimalaccount)), AMOUNT);
    }
}
