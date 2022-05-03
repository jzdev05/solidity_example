// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../ONFT721Core.sol";

contract ProxyONFT721 is ONFT721Core, IERC721Receiver {
    IERC721 public immutable token;

    constructor(address _lzEndpoint, address _proxyToken) ONFT721Core(_lzEndpoint) {
        token = IERC721(_proxyToken);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // TODO: ERC165
    }

    function sendFrom(
        address, /* _from */
        uint16, /* _dstChainId */
        bytes calldata, /* _toAddress */
        uint, /* _tokenId */
        address payable, /* _refundAddress */
        address, /* _zroPaymentAddress */
        bytes calldata /* _adapterParams */
    ) public payable virtual override {
        revert("ProxyONFT721: no implementer");
    }

    function _debitFrom(
        address _from,
        uint16, /* _dstChainId */
        bytes memory, /* _toAddress */
        uint _tokenId
    ) internal virtual override {
        token.safeTransferFrom(_from, address(this), _tokenId);
    }

    function _creditTo(
        uint16, /* _srcChainId */
        address _toAddress,
        uint _tokenId
    ) internal virtual override {
        token.safeTransferFrom(address(this), _toAddress, _tokenId);
    }

    function onERC721Received(
        address _operator,
        address,
        uint,
        bytes memory
    ) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return IERC721Receiver.onERC721Received.selector;
    }
}
