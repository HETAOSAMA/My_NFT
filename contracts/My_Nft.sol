// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./lib/utils/EthToUsd.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyNft is ERC721URIStorage {
    using EthToUsd for uint256;
    address owner;
    //权限控制
    mapping (address =>(mapping string => bool)) public hasRole;
    uint256 public MAX_APES = 10000; // 总量
    uint256 private _nextTokenId = 1; // 下一个NFT的ID, 从1开始,因为省gas
    //mint事件
    event Mint(address indexed to, uint256 amount);
    //权限事件
    event RoleAdded(address indexed to, string role, bool isApproved);
    //ERC721指定NFT的名字和简称 
    constructor() ERC721("MyNft", "MNFT"){
        owner = msg.sender;
    }

    function getEthToUsd() public payable {
        require(msg.velue.convert() >= 100, "Not enough ETH");
        
        require(tokenId < MAX_APES, "All MyNft have been minted");
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, "https://ipfs.io/ipfs/QmZ ...");
        uint256 tokenId = _nextTokenId++;
        //mint 1个NFT
        emit Mint(msg.sender, 1);
    }

    //添加权限
    function addRole(address _address, string memory _role, bool isApproved) public {
        require(msg.sender == owner, "You are not the owner");
        hasRole[_address][_role] = isApproved;
        //释放权限事件
        emit RoleAdded(_address, _role, isApproved);
    }   

    //将合约中的所有ETH转给调用者，调用者必须拥有权限
    function withdraw public{
        require(hasRole[msg.sender]["withdraw"], "You are not the owner");
        //transfer gass上限为2300，会主动抛出异常
        // payable(msg.sender).transfer(address(this).balance);
        // send gass上限为2300，不会主动抛出异常, 会返回false
        // payable(msg.sender).send(address(this).balance);
        // call gass无上限，不会主动抛出异常, 会返回false，因为我不需要调用fuction所以留空
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
}

