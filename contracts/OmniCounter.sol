// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";

contract OmniCounter is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using SafeMath for uint;
    // keep track of how many messages have been received from other chains
    uint public messageCounter;
    // required: the LayerZero endpoint which is passed in the constructor
    ILayerZeroEndpoint public endpoint;

    constructor(address _endpoint) {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    function getCounter() public view returns (uint) {
        return messageCounter;
    }

    // overrides lzReceive function in ILayerZeroReceiver.
    // automatically invoked on the receiving chain after the source chain calls endpoint.send(...)
    function lzReceive(
        uint16,
        bytes memory, /*_fromAddress*/
        uint64, /*_nonce*/
        bytes memory /*_payload*/
    ) external override {
        require(msg.sender == address(endpoint));
        messageCounter += 1;
    }

    // custom function that wraps endpoint.send(...) which will
    // cause lzReceive() to be called on the destination chain!
    function incrementCounter(uint16 _dstChainId, bytes calldata _dstCounterMockAddress) public payable {
        endpoint.send{value: msg.value}(_dstChainId, _dstCounterMockAddress, bytes(""), payable(msg.sender), address(0x0), bytes(""));
    }

    // _adapterParams (v1)
    function incrementCounterWithAdapterParamsV1(uint16 _dstChainId, bytes calldata _dstCounterMockAddress, uint gasAmountForDst) public payable {
        uint16 version = 1;
        // make look like this: 0x00010000000000000000000000000000000000000000000000000000000000030d40
        bytes memory _relayerParams = abi.encodePacked(
            version,
            gasAmountForDst
        );
        endpoint.send{value: msg.value}(_dstChainId, _dstCounterMockAddress, bytes(""), payable(msg.sender), address(0x0), _relayerParams);
    }

    // _adapterParams (v2)
    function incrementCounterWithAdapterParamsV2(uint16 _dstChainId, bytes calldata _dstCounterMockAddress, uint gasAmountForDst, uint airdropEthQty, address airdropAddr) public payable {
        uint16 version = 2;
        bytes memory _relayerParams = abi.encodePacked(
            version,
            gasAmountForDst,
            airdropEthQty,
            airdropAddr
        );
        endpoint.send{value: msg.value}(_dstChainId, _dstCounterMockAddress, bytes(""), payable(msg.sender), address(0x0), _relayerParams);
    }

    // call send() to multiple destinations in the same transaction!
    function incrementCounterMulti(uint16[] calldata _dstChainIds, bytes[] calldata _dstCounterMockAddresses, address payable _refundAddr) public payable {
        require(_dstChainIds.length == _dstCounterMockAddresses.length, "_dstChainIds.length, _dstCounterMockAddresses.length not the same");

        uint numberOfChains = _dstChainIds.length;

        // note: could result in a few wei of dust left in contract
        uint valueToSend = msg.value.div(numberOfChains);

        // send() each chainId + dst address pair
        for (uint i = 0; i < numberOfChains; ++i) {
            // a Communicator.sol instance is the 'endpoint'
            // .send() each payload to the destination chainId + UA destination address
            endpoint.send{value: valueToSend}(_dstChainIds[i], _dstCounterMockAddresses[i], bytes(""), _refundAddr, address(0x0), bytes(""));
        }

        // refund eth if too much was sent into this contract call
        uint refund = msg.value.sub(valueToSend.mul(numberOfChains));
        _refundAddr.transfer(refund);
    }

    function setConfig(
        uint16, /*_dstChainId*/
        uint _configType,
        bytes memory _config
    ) external override {
        endpoint.setConfig(endpoint.getSendVersion(), _configType, _config);
    }

    function getConfig(
        uint16, /*_dstChainId*/
        uint16 _chainId,
        address,
        uint _configType
    ) external view override returns (bytes memory) {
        return endpoint.getConfig(endpoint.getSendVersion(), _chainId, address(this), _configType);
    }

    function setSendVersion(uint16 version) external override {
        endpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override {
        endpoint.setReceiveVersion(version);
    }

    function getSendVersion() external view override returns (uint16) {
        return endpoint.getSendVersion();
    }

    function getReceiveVersion() external view override returns (uint16) {
        return endpoint.getReceiveVersion();
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
        // do nth
    }


    // allow this contract to receive ether
    fallback() external payable {}
    receive() external payable {}

}
