// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTSwap is IERC721Receiver {

    struct Order {
        address owner;
        uint256 tokenId;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Order)) public orders;

    //上架事件(indexed 关键字声明的事件参数，其值将会被编码到区块链上的事件日志中，而不仅仅是普通的事件数据,最多三个参数可以使用该关键字)
    event Sell(address indexed seller, address indexed nftAddr, uint256 indexed tokenId,uint256 price);
    //购买事件
    event Buy(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId,uint256 price);

    // ERC721回调函数
    function onERC721Received(
        address,
        address,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    // 参数为NFT合约地址_nftAddr，NFT对应的_tokenId，挂单价格_price（注意：单位是wei）。
    // NFT会从卖家转到NFTSwap合约中。
    function sell(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require(_nft.getApproved(_tokenId) == address(this), "Need approved");
        // 将NFT转账到合约
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        orders[_nftAddr][_tokenId] = Order(msg.sender, _tokenId, _price);

        emit Sell(msg.sender, _nftAddr, _tokenId, _price);
    }

    // 买家调用buy函数，参数为NFT合约地址_nftAddr，NFT对应的_tokenId。
    // 买家需要支付挂单价格，NFT会从NFTSwap合约转到买家。
    function buy(address _nftAddr, uint256 _tokenId) public payable {
        Order storage _order = orders[_nftAddr][_tokenId];
        uint256 _price = _order.price;
        // 买家不能是卖家
        require(_order.owner != address(msg.sender), "Invalid order");
        // 买家支付的价格必须等于挂单价格
        require(msg.value == _order.price, "Invalid price");

        IERC721 _nft = IERC721(_nftAddr);
        // NFT必须在NFTSwap合约中
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");

        // 将NFT转账给买家, 买家支付的eth转账给卖家,多余的eth会退回给买家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        (bool success, ) = payable(_order.owner).call{value: _price}("");
        require(success, "buy failed");
        (bool flag, ) = payable(msg.sender).call{value: msg.value - _price}("");
        require(flag, "refund failed");

        // 删除挂单
        delete orders[_nftAddr][_tokenId];

        emit Buy(msg.sender, _nftAddr, _tokenId, _price);
    }


}