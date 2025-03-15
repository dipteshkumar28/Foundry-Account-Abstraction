// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "lib/forge-std/src/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();
    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address constant BURNER_WALLET = 0x5521D4B3FBc9dCa3ffC5bf2073e09A715346ff21;
    address constant FOUNDRY_WALLET =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainid => NetworkConfig) public netwokconfigs;

    constructor() {
        netwokconfigs[ETH_SEPOLIA_CHAIN_ID] = ethsepoliaConfig();
    }

    function getconfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public view returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (netwokconfigs[chainId].entryPoint != address(0)) {
            return netwokconfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function ethsepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entryPoint: 0x5521D4B3FBc9dCa3ffC5bf2073e09A715346ff21,
                account: BURNER_WALLET
            });
    }

    function ethZKsyncsepoliaConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }

    function getOrCreateAnvilEthConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        return NetworkConfig({entryPoint: address(0), account: FOUNDRY_WALLET});
    }
}
