// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

contract MarketProxy {
    constructor(address _implementation, bytes memory _initData) {
        assembly {
            sstore(0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC, _implementation)
        }
        (bool ok, ) = _implementation.delegatecall(_initData);
        require(ok, "init failed");
    }

    fallback() external payable {
        assembly {
            let impl := sload(0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC)
            calldatacopy(0, 0, calldatasize())
            let res := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch res
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
