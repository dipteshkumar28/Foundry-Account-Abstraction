// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "lib/forge-std/src/Test.sol";
import {ZkMinimalAccount} from "src/zksync/zkSyncMinimalAccount.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {Transaction, MemoryTransactionHelper} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";

contract ZkSyncMinimalAccountTest is Test {
    ZkMinimalAccount public zkMinimalAccount;
    ERC20Mock public usdc;

    uint256 constant AMOUNT = 1e18;
    address constant ANVIL_DEFAULT_ACCOUNT= 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32 constant EMPTY_BYTES32 = bytes32(0);

    function setUp() external {
        zkMinimalAccount = new ZkMinimalAccount();
        zkMinimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
        usdc = new ERC20Mock();
        vm.deal(address(zkMinimalAccount), AMOUNT);
    }

    function testZkSyncOwnerCanExecuteCommands() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functiondata = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(zkMinimalAccount),
            AMOUNT
        );
        Transaction memory transction = _createUnsignedTransaction(
            zkMinimalAccount.owner(),
            113,
            dest,
            value,
            functiondata
        );

        vm.prank(zkMinimalAccount.owner());
        zkMinimalAccount.executeTransaction(
            EMPTY_BYTES32,
            EMPTY_BYTES32,
            transction
        );

        assertEq(usdc.balanceOf(address(zkMinimalAccount)), AMOUNT);
    }

    function testZkValidateTransaction() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functiondata = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(zkMinimalAccount),
            AMOUNT
        );
        Transaction memory transaction = _createUnsignedTransaction(
            zkMinimalAccount.owner(),
            113,
            dest,
            value,
            functiondata
        );
        transaction = _signTransaction(transaction);
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic = zkMinimalAccount.validateTransaction(
            EMPTY_BYTES32,
            EMPTY_BYTES32,
            transaction
        );

        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    function _signTransaction(
        Transaction memory transaction
    ) internal view returns (Transaction memory) {
        bytes32 unsignedHashTransaction = MemoryTransactionHelper.encodeHash(
            transaction
        );
        // bytes32 digest = unsignedHashTransaction.toEthSignedMessageHash();
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, unsignedHashTransaction);
        Transaction memory signedTransaction = transaction;
        signedTransaction.signature = abi.encodePacked(r, s, v);
        return signedTransaction;
    }

    function _createUnsignedTransaction(
        address from,
        uint8 transactiontype,
        address to,
        uint256 value,
        bytes memory data
    ) internal view returns (Transaction memory) {
        uint256 nonce = vm.getNonce(address(zkMinimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);
        return
            Transaction({
                txType: transactiontype,
                from: uint256(uint160(from)),
                to: uint256(uint160(to)),
                gasLimit: 16777216,
                gasPerPubdataByteLimit: 16777216,
                maxFeePerGas: 16777216,
                maxPriorityFeePerGas: 16777216,
                paymaster: 0,
                nonce: nonce,
                value: value,
                reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
                data: data,
                signature: hex"",
                factoryDeps: factoryDeps,
                paymasterInput: hex"",
                reservedDynamic: hex""
            });
    }
}
