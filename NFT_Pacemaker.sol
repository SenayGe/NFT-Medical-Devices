// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.5.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.5.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.5.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.5.0/utils/Counters.sol";

contract VerifyDevice {
    mapping (address => bool) isApproved;
    //mapping submittedMetadata
    address FDA = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    string manufacturer = "Manufacturer-A" ;
    string deviceName = "Pacemaker";
    string modelNumber = "PM-A2SR05";
    uint serialNumber ;
  
    // constructor (){
    //     fee = 1 ether;
    // }
    string metadata = "https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXVPiikMJ8u2NLgmgszg13pYrDKEoiu";
    event MintRequested (address addr);
    event CheckingApproval (address a);
    event RequestForDeviceApproval (string metadata, string device, string producer );
    event DeviceApprovedByFDA (address owner, string device, string model);

    function approveDevice (address user) public onlyFDA{
        isApproved[user] = true;
        emit DeviceApprovedByFDA(user, deviceName, modelNumber);
    }

    function requestApproval (string memory _deviceName, uint serialNo) public{
        serialNumber = serialNo;
        emit RequestForDeviceApproval (metadata, deviceName, manufacturer);
        
    }
    // function requestApproval () public payable {
    //     require(msg.value == fee);
    //     emit RequestForDeviceApproval (metadata, deviceName, manufacturer);
        
    // }
    function checkApprvoal(address user) public view returns(bool){
        return isApproved[user];
    }
    function createNFT (address _nft, address to) public returns(uint256){
        
        require (isApproved [to],"Device is not approved");
        isApproved[to] = false;
        return PacemakerNFT (_nft).mintNFT(to);

    }

    modifier onlyFDA(){ //only sender who is the owner
        require(msg.sender == FDA); 
        _;
    }
}


contract PacemakerNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    string deviceName = "Pacemaker";
    string modelNumber = "PM-A2SR05";
    string lockReason = "NFT transfer function is locked until physical device is delivered to buyer";
    string unlockDescription = "Buyer received physical medical device";
    string metadata = "https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXVPiikMJ8u2NLgmgszg13pYrDKEoiu";

    Counters.Counter private _tokenIdCounter;
    address verifierSC;
    event NFTmintedForDevice(uint256 TokenId, address Owner, string DeviceName, string ModelNo, string Metadata );
    event OwnershipTransferred (uint256 tokenID, address from, address to);
    event NFTtransferLocked (uint TokenID, string Reason);
    event NFTUnlocked (uint TokenID, address Owner,string unlockDescription );
    event ReceiverConfirmsDelivery (uint TokenID, address Receiver);
    constructor() ERC721("PacemakerNFT", "PCMKR") {
        verifierSC = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    }

    function mintNFT(address to) public  returns(uint256){ //string memory uri
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        emit NFTmintedForDevice(tokenId, to, deviceName, modelNumber, metadata);
        return tokenId;
       // _setTokenURI(tokenId, uri);
    }

    function transferOwnership(address from, address to, uint256 tokenID ) public {
        safeTransferFrom(from, to, tokenID);
        emit OwnershipTransferred(tokenID, from, to);
        emit NFTtransferLocked (tokenID, lockReason);
    }
    function unlockNFT (uint _tokenID) public{
        emit ReceiverConfirmsDelivery (_tokenID, msg.sender);
        emit NFTUnlocked(_tokenID, msg.sender, unlockDescription);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    modifier onlyMinter(){ //only sender who is the owner
        require(msg.sender == verifierSC); 
        _;
    }
}

