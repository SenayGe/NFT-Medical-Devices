pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.5.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.5.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.5.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.5.0/utils/Counters.sol";

contract VerificationManager {

    address contractOwner;
    address FDA = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address Manufacturer = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address NFTcontract;
    //mapping (address => bool) isApproved;
    mapping (string => bool) approvedDevices;
    mapping (address => string) submittedRequest;
    mapping (uint => MedicalDevice) medicalDevices;
    string _manufacturer = "Manufacturer-A" ;
    string _deviceName = "Pacemaker";
    string _modelNumber = "PM-A2SR05";
    string _metadata = "https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXVPiikMJ8u2NLgmgszg13pYrDKEoiu";
    enum DeviceStatus { NOT_APPROVED, APPROVAL_PENDING, APPROVED, APPROVAL_REJECTED, NFT_MINTED}
    event MintRequested (address addr);
    event CheckingApproval (address a);
    event RequestForDeviceApproval (string metadata, string device, address producer );
    event DeviceApprovedByFDA (uint _deviceID, string deviceName, string model);
    event DeviceRejectedByFDA (uint _deviceID, string deviceName, string model);
  
  
    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner(){ 
        require(msg.sender == contractOwner); 
        _;
    }
    modifier onlyFDA(){ 
        require(msg.sender == FDA); 
        _;
    }
    modifier onlyManufacturer(){ 
        require(msg.sender == Manufacturer); 
        _;
    }

    struct MedicalDevice {
        uint deviceId;
        string name;
        string modelNumber;
        address manufacturer;
        string metadata;
        DeviceStatus status;
        
    }
    
    function setNFTcontractAddress (address NFTcontractAddr) onlyOwner public{
        NFTcontract = NFTcontractAddr;
    }

    // The following function can be implemented on the DAPP
    function submitMedicalDevice (uint id, string memory deviceName, string memory modelNumber, string memory deviceMetadata) public onlyManufacturer{
        require ( medicalDevices[id].deviceId > 0 == false, "device already exists");
        medicalDevices [id] = MedicalDevice(id, deviceName, modelNumber, msg.sender, deviceMetadata, DeviceStatus.NOT_APPROVED);

    }

    // request approval is called after submitting medical device with all the necessary information
    function requestApproval (uint deviceId) public onlyManufacturer{
        MedicalDevice memory device = medicalDevices[deviceId];
        require (device.status == DeviceStatus.NOT_APPROVED);
        emit RequestForDeviceApproval (device.metadata, device.name, msg.sender);  
    }

    function approveDevice (uint deviceId, bool isApproved) public onlyFDA{
        if (isApproved == true){
            medicalDevices[deviceId].status = DeviceStatus.APPROVED; 
            emit DeviceApprovedByFDA(deviceId, medicalDevices[deviceId].name, medicalDevices[deviceId].modelNumber);
        }
        else {
            medicalDevices[deviceId].status = DeviceStatus.APPROVAL_REJECTED;
        }
        
       
    }

    // function checkApprvoal(address user) public view returns(bool){
    //     return isApproved[user];
    // }
    function createNFT (uint deviceId, address to) public{
        
        require ( medicalDevices[deviceId].status == DeviceStatus.APPROVED,"Device is not approved");
        MedicalDeviceNFT (NFTcontract).mintNFT(to);
        medicalDevices[deviceId].status = DeviceStatus.NFT_MINTED;
       
    }

    
}



contract MedicalDeviceNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    address verifierContract;
    //address owner;
    string recevedCode;
    Counters.Counter private _tokenIdCounter;
    mapping (uint => bool) isTokenLocked;
    string private _myBaseUri;
    
    // test data
    string deviceName = "Pacemaker";
    string modelNumber = "PM-A2SR05";
    string lockReason = "NFT transfer function is locked until physical device is delivered to buyer";
    string unlockDescription = "Buyer received physical medical device";
    string metadata = "https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXVPiikMJ8u2NLgmgszg13pYrDKEoiu";
    string passphrase = "pcmkr12384786e";
    
    event NFTmintedForDevice(uint256 TokenId, address Owner, string DeviceName, string ModelNo );
    event OwnershipTransferred (uint256 tokenID, address from, address to);
    event NFTtransferLocked (uint TokenID, string Reason);
    event NFTUnlocked (uint TokenID, address Owner,string unlockDescription );
    event ReceiverConfirmsDelivery (uint TokenID, address Receiver);
    constructor() ERC721("PacemakerNFT", "PCMKR") {
        verifierContract = 0x1482717Eb2eA8Ecd81d2d8C403CaCF87AcF04927;
        _myBaseUri = "https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXVPiikMJ8u2NLgmgszg13pYrDKEoiu";
  
    }


    modifier onlyVerifierContract{
        require(msg.sender == verifierContract); 
        _;
    }

    function mintNFT(address to) public  onlyVerifierContract{ //string memory uri
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        //_setTokenURI(tokenId, _metadata);
        isTokenLocked[tokenId] = false;
        emit NFTmintedForDevice(tokenId, to, deviceName, modelNumber);
        
       // _setTokenURI(tokenId, uri);
    }

    function transferOwnership(address from, address to, uint256 tokenID ) public {
        require (isTokenLocked[tokenID] == false, "device is being delivered");
        safeTransferFrom(from, to, tokenID);
        emit OwnershipTransferred(tokenID, from, to);
        emit NFTtransferLocked (tokenID, lockReason);
    }

    function lockNFT (uint _tokenID) public onlyOwner{
        isTokenLocked[_tokenID] = true;
    }
    // the passphrase code is generated uniquely whenever the device is shipped
    function unlockNFT (uint _tokenID, string memory code) public onlyOwner{
        require (isTokenLocked[_tokenID] = true);
        recevedCode = code;
         if(keccak256(abi.encodePacked(passphrase)) == keccak256(abi.encodePacked(recevedCode))){//authenticated
            isTokenLocked[_tokenID] = false;
         }
        emit ReceiverConfirmsDelivery (_tokenID, msg.sender);
        emit NFTUnlocked(_tokenID, msg.sender, unlockDescription);
        
    }
    
    function setVerifierContractAddr (address addr) public{
        verifierContract = addr;
    }
    
    function setBaseUri (string memory newBaseUri) public onlyOwner {
        _myBaseUri = newBaseUri;
    }

    // The following functions are overrides required by Solidity.

    function _baseURI() internal view virtual override returns (string memory) {
        return _myBaseUri;
    }

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
    
}