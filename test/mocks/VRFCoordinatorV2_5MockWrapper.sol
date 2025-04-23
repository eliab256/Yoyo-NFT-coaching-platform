// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract VRFCoordinatorV2_5MockWrapper is VRFCoordinatorV2_5Mock {
    struct RequestPublic {
        uint256 subId;
        uint32 callbackGasLimit;
        uint32 numWords;
        bytes extraArgs;
    }

    constructor(
        uint96 _baseFee,
        uint96 _gasPrice,
        int256 _weiPerUnitLink
    ) VRFCoordinatorV2_5Mock(_baseFee, _gasPrice, _weiPerUnitLink) {}

    function getRequest(
        uint256 _requestId
    ) public view returns (RequestPublic memory) {
        Request memory request = s_requests[_requestId];
        return
            RequestPublic(
                request.subId,
                request.callbackGasLimit,
                request.numWords,
                request.extraArgs
            );
    }

    function getSubscriptionBalance(
        uint256 _subId
    ) public view returns (uint256) {
        (uint96 balance, , , , ) = getSubscription(_subId);
        return uint256(balance);
    }
}
