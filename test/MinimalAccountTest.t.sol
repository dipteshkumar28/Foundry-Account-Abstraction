// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MinimalAccount} from "../src/Ethereum/MinimalAccount.sol";
import {DeployMinimal} from "../script/DeployMinimal.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "../script/SendPackedUserOp.s.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperconfig;
    MinimalAccount minimalaccount;
    ERC20Mock usdc;
    SendPackedUserOp sendpackeduserop;

    uint256 constant AMOUNT = 1e18;
    address randomUser = makeAddr("randomUser");

    function setUp() public {
        DeployMinimal deployminimal = new DeployMinimal();
        (helperconfig, minimalaccount) = deployminimal.deployminimal();
        usdc = new ERC20Mock();
        sendpackeduserop = new SendPackedUserOp();
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

    function testNotOwnerCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalaccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcdata = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalaccount),
            AMOUNT
        );

        vm.prank(randomUser);
        vm.expectRevert(
            MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector
        );
        minimalaccount.execute(dest, value, funcdata);
    }

    function testRecoverSignedOp() public {
        assertEq(usdc.balanceOf(address(minimalaccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcdata = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalaccount),
            AMOUNT
        );
        bytes memory callData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            funcdata
        );
        PackedUserOperation memory packedUserOp = sendpackeduserop
            .generatedSignedUserOperation(
                callData,
                helperconfig.getconfig(),
                address(minimalaccount)
            );

        bytes32 userOperationHash = IEntryPoint(
            helperconfig.getconfig().entryPoint
        ).getUserOpHash(packedUserOp);

        address actualsigner = ECDSA.recover(
            userOperationHash.toEthSignedMessageHash(),
            packedUserOp.signature
        );

        assertEq(actualsigner, minimalaccount.owner());
    }

    function testValidationUserOp() public {
        assertEq(usdc.balanceOf(address(minimalaccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcdata = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalaccount),
            AMOUNT
        );
        bytes memory callData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            funcdata
        );
        PackedUserOperation memory packedUserOp = sendpackeduserop
            .generatedSignedUserOperation(
                callData,
                helperconfig.getconfig(),
                address(minimalaccount)
            );

        bytes32 userOperationHash = IEntryPoint(
            helperconfig.getconfig().entryPoint
        ).getUserOpHash(packedUserOp);

        uint256 missingAccountFunds = 1e18;
        vm.deal(address(minimalaccount), 2 ether);

        vm.prank(helperconfig.getconfig().entryPoint);
        uint256 validationData = minimalaccount.validateUserOp(
            packedUserOp,
            userOperationHash,
            missingAccountFunds
        );
        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalaccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcdata = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalaccount),
            AMOUNT
        );
        bytes memory callData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            funcdata
        );
        PackedUserOperation memory packedUserOp = sendpackeduserop
            .generatedSignedUserOperation(
                callData,
                helperconfig.getconfig(),
                address(minimalaccount)
            );

        vm.deal(address(minimalaccount), 10 ether);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        vm.prank(randomUser);
        IEntryPoint(helperconfig.getconfig().entryPoint).handleOps(
            ops,
            payable(randomUser)
        );

        assertEq(usdc.balanceOf(address(minimalaccount)), AMOUNT);
    }
}
