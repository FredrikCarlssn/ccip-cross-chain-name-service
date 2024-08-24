// test/CCIPCrossChainNameServiceTest.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IRouterClient, CCIPLocalSimulator, WETH9, LinkToken, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {CrossChainNameServiceRegister} from "../contracts/CrossChainNameServiceRegister.sol";
import {CrossChainNameServiceReceiver} from "../contracts/CrossChainNameServiceReceiver.sol";
import {CrossChainNameServiceLookup} from "../contracts/CrossChainNameServiceLookup.sol";

contract CCIPCrossChainNameServiceTest is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    CrossChainNameServiceRegister public crossChainNameServiceRegister;
    CrossChainNameServiceReceiver public crossChainNameServiceReceiver;
    CrossChainNameServiceLookup public crossChainNameServiceLookup;
    CrossChainNameServiceLookup public crossChainNameServiceLookup2;
    address public aliceEOA =
        address(0xc9c81Af14eC5d7a4Ca19fdC9897054e2d033bf05);

    function setUp() public {
        // Deploy CCIPLocalSimulator
        ccipLocalSimulator = new CCIPLocalSimulator();

        // Get Router contract address
        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            WETH9 wrappedNative,
            LinkToken linkToken,
            BurnMintERC677Helper ccipBnM,
            BurnMintERC677Helper ccipLnM
        ) = ccipLocalSimulator.configuration();

        // Deploy CrossChainNameServiceLookup
        crossChainNameServiceLookup = new CrossChainNameServiceLookup();

        // Deploy CrossChainNameServiceRegister
        crossChainNameServiceRegister = new CrossChainNameServiceRegister(
            address(sourceRouter),
            address(crossChainNameServiceLookup)
        );

        crossChainNameServiceLookup.setCrossChainNameServiceAddress(
            address(crossChainNameServiceRegister)
        );

        crossChainNameServiceRegister.enableChain(
            chainSelector,
            address(destinationRouter),
            500000
        );

        crossChainNameServiceLookup2 = new CrossChainNameServiceLookup();

        // Deploy CrossChainNameServiceReceiver
        crossChainNameServiceReceiver = new CrossChainNameServiceReceiver(
            address(destinationRouter),
            address(crossChainNameServiceLookup2),
            chainSelector
        );

        crossChainNameServiceLookup2.setCrossChainNameServiceAddress(
            address(crossChainNameServiceReceiver)
        );
    }

    function test_RegisterAndLookup() public {
        // Register alice.ccns
        vm.prank(aliceEOA);
        crossChainNameServiceRegister.register("alice.ccns");

        // Lookup alice.ccns

        address result = crossChainNameServiceLookup.lookup("alice.ccns");
        assertEq(result, aliceEOA);
    }
}
