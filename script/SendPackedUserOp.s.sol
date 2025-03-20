// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MinimalAccount} from "../src/Ethereum/MinimalAccount.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    address constant RANDOM_APPROVER =
        0x9EA9b0cc1919def1A3CfAEF4F7A66eE3c36F86fC;

    function run() public {
        HelperConfig helperconfig = new HelperConfig();
        address dest = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // arbitrum mainnet USDC address
        uint256 value = 0;
        bytes memory funcdata = abi.encodeWithSelector(
            IERC20.approve.selector,
            RANDOM_APPROVER,
            1e18
        );
        bytes memory callData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            funcdata
        );
        PackedUserOperation memory userOp = generatedSignedUserOperation(
            callData,
            helperconfig.getconfig(),
            0x03Ad95a54f02A40180D45D76789C448024145aaF
        );
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
        vm.startBroadcast();
        IEntryPoint(helperconfig.getconfig().entryPoint).handleOps(
            ops,
            payable(helperconfig.getconfig().account)
        );
        vm.stopBroadcast();
    }

    function generatedSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        console.log(nonce);
        PackedUserOperation
            memory unsignedUserOp = __generateUnSignedUserOperation(
                callData,
                minimalAccount,
                nonce
            );

        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            unsignedUserOp
        );
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        unsignedUserOp.signature = abi.encodePacked(r, s, v);
        return unsignedUserOp;
    }

    function __generateUnSignedUserOperation(
        bytes memory callData,
        address sender,
        uint256 nonce
    ) internal pure returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return
            PackedUserOperation({
                sender: sender,
                nonce: nonce,
                initCode: hex"",
                callData: callData,
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) | callGasLimit
                ),
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ),
                paymasterAndData: hex"",
                signature: hex""
            });
    }
}
