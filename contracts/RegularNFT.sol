// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

string constant name = "RegularNFT";
string constant symbol = "RNFT";

contract RegularNFT is ERC721(name, symbol), ReentrancyGuard{
    //The library of String operations and used here for uint256
    using Strings for uint256;
    
    //Total Supply of the NFTs, updated only after function mintAll is called
    uint256 public totalSupply;

    //Smart Contract Deployer
    address owner;

    //Mapping to show if or not user has minted
    mapping(address => bool) internal _hasUserMinted;

    // Struct holding NFT's tokenId and uri
    struct AllMints {
        uint256 _tokenId;
        string _uri;
    }

    // Variable for storing user-defined data type struct
    AllMints saveMint;
    // Array containing user-defined variables of data type struct
    AllMints[] saveMints;

    // This function runs only once at the beginning and running of the contract
    constructor() {
        owner = msg.sender;
    }

    // This enforces that the msg.sender must be same address as the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, 'Must be RegularNFT deployer');
        _;
    }
    //Requires the sender not to be the owner i.e. smart contract deployer address
    modifier notOwner() {
        require(msg.sender != owner, 'Must not be the contract owner');
        _;
    }
    //Ensures the correct amount is sent
    modifier incorrectAmount() {
        require(msg.value == (5*(10**15)), 'Incorrect amount of Ether sent');
        _;
    }

    event Mint(address indexed _to, uint256 _tokenId, string _tokenURI);

    // An Internal function overriding the parent function _baseURI() from ERC721 for
    // returning the base URI unto which tokenId is added to give URL of each NFT
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/QmSrSwboxekwhUfK5nKcbzK6xuTmNxhsiz643pmjqJfqPt/";
    }
    
    // The publicly viewable function returning the baseURI
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    // Mint function for any user aside the owner and address(0) to mint a token.
    // User must send 0.005 ether to mint, and, this is guarded against ReEntrancy
    function mint(bytes memory _data, uint256 _tokenId) public payable 
    notOwner incorrectAmount nonReentrant returns (bool) {
        
        //This condition makes sure a user only mints once
        if(_hasUserMinted[msg.sender] == false) {
            //The uri i.e. IPFS storage path for the NFT
            string memory uri_ = string(
                abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".jpg")
            );
            // Store the tokenId, uri into the variable saveMint
            saveMint = AllMints(_tokenId, uri_);
            // Store the variable saveMint (and its content) into the array saaveMints
            saveMints.push(saveMint);

            // Send the received ether (from the user/sender) to the owner
            uint256 val = msg.value;
            require(address(this).balance >= val, 'Ether insufficient');
            (bool success, ) = owner.call{value: val}("");

            //Mint the token, update the total supply, and emit a mint event
            _safeMint(msg.sender, _tokenId, _data);
            totalSupply++;
            emit Mint(msg.sender, _tokenId, uri_);

            //Once user has minted, turns true to disallow the same user to mint again
            _hasUserMinted[msg.sender] = true;
            
            return success;
        } else {
            //Reverts the operation if the user has minted this token before
            revert();
        }
    }

    // The Function which mints the ERC721 tokens according to the owner input in loop
    function mintAll(bytes memory data, uint256 total) onlyOwner 
    public payable returns (AllMints[] memory) {

        AllMints[] memory allMints = new AllMints[](total + 1);
        for (uint256 i = 1; i < (total + 1); i++) {

            string memory _uri = string(
                abi.encodePacked(_baseURI(), Strings.toString(i), ".jpg")
            );
            console.log(_uri);
            _safeMint(msg.sender, i, data);
            allMints[i] = AllMints(i, _uri);
            totalSupply++;
        }
        return allMints;
    }

    // Transfers ERC721 token from the caller's address to another address
    function transferTo(address _to, uint256 _tokenId) public payable {
        approve(_to, _tokenId);
        console.log(getApproved(_tokenId));
        safeTransferFrom(msg.sender, _to, _tokenId, "0x");
        console.log('Balance of stakeAddress: %s', this.balanceOf(_to));
    }

    // Returns the array of struct AllMints and all that has been stored in it
    function allMintsShow() public view returns (AllMints[] memory) {
        return saveMints;
    }
}