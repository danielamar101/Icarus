// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract DreamPass is ERC1155, Ownable {
    using SafeMath for uint;

    //First dreampass
    uint256 public DREAM_PASS_ID = 0;

    uint256 public maxQuantity;
    uint256 public mintCounter = 0;

    mapping(address => uint) comicAddressMap;
    mapping(uint => address) comicIdToAddressMap;

    uint public distinctPassCount;

    event AnnounceMint(address minter, uint id, uint count);
    event AnnounceBurn(address burner, uint id, uint count);

    //Create authentication around a comic book
    modifier onlyComic(address _address){
        if(comicIdToAddressMap[comicAddressMap[_address]] == _address){
            _;
        } else{
            revert("The comic must call this method!");
        }
    }

    constructor(uint256 _maxQuantity, string memory _contractURI) ERC1155(_contractURI) {
        maxQuantity = _maxQuantity;
    }

    function mintDreampass() external{
        require(mintCounter < maxQuantity, "All dreampasses have been minted!");
        require(balanceOf(msg.sender,0) == 0, "You already have a dreampass!");

        _mint(msg.sender, DREAM_PASS_ID,1, "");

        mintCounter = SafeMath.add(mintCounter,1);

        emit AnnounceMint(msg.sender,DREAM_PASS_ID, mintCounter);
    }

    function burnAndMintDreampass(address _playerAddress) external onlyComic(msg.sender){
        //Determine if player owns any dreampass
        uint256 idToBurn = getHighestOwnedDreampassId(_playerAddress);
        _burn(_playerAddress,idToBurn, 1);

        emit AnnounceMint(msg.sender,idToBurn, 1);

        _mint(_playerAddress,idToBurn + 1, 1,"");
        emit AnnounceMint(msg.sender,idToBurn + 1, 1);
    }

    function returnArrayOfOwnedPasses(address _address) public view returns (uint256[] memory _quantityArray, uint256 _amountOfPasses){
        uint256 dreampassIdCounter = 1;
        uint256[] memory quantityArray;
        uint256 amountOfPasses;
        while(dreampassIdCounter < distinctPassCount){
            uint256 currentTokenCount = balanceOf(_address,dreampassIdCounter);
            if(currentTokenCount > 0){
                quantityArray[dreampassIdCounter] = currentTokenCount;
                amountOfPasses += currentTokenCount;
            }else{
                quantityArray[dreampassIdCounter] = 0;
            }
            dreampassIdCounter++;
        }

        return (quantityArray, amountOfPasses);
    }

    function hasDreampass(address _address) public view returns (bool){
        (uint256[] memory quantityArray, uint256 amountOfPasses) = returnArrayOfOwnedPasses(_address);

        if(amountOfPasses > 0){
            return true;
        } else{
            return false;
        }
    }

    function getHighestOwnedDreampassId(address _address) public returns (uint256) {
        (uint256[] memory quantityArray, uint256 amountOfPasses) = returnArrayOfOwnedPasses(_address);
        require(amountOfPasses > 0, "You don't have any passes!");

        uint256 counter = quantityArray.length-1;
        while(counter > 0){
            if(quantityArray[counter] > 0){
                return counter;
            }
        }
    }

    function setDistinctPassQuantity(uint256 _value) public onlyOwner{
        distinctPassCount = _value;
    }

}

contract Comic is ERC1155, Ownable {
    using SafeMath for uint;

    uint256 public COMIC_ID;
    uint256 public priceToMintDiscounted;
    uint256 public priceToMintFull;
    uint256 public maxQuantity;
    uint256 public mintCounter;

    DreamPass dreampassContract;
    address public dreampassAddress;

    uint public releasedComicsUpTo;

    event AnnounceMint(address minter, uint id);
    event AnnounceComicRelease(string message, uint id);

    constructor(uint256 _id,uint256 _priceToMintDiscounted, uint256 _priceToMintFull, uint256 _maxQuantity,
    string memory _contractURI, address _dreampassAddress) ERC1155(_contractURI) {
        COMIC_ID = _id;
        priceToMintDiscounted = _priceToMintDiscounted;
        priceToMintFull = _priceToMintFull;
        maxQuantity = _maxQuantity;
        mintCounter = 0;

        //Sets the dreampass address to use as reference
        dreampassContract = DreamPass(_dreampassAddress);
        dreampassAddress = _dreampassAddress;
    }

    function setDreamPassAddress(address _address) external onlyOwner {
        dreampassAddress = _address;
    }

    function mintComic() payable external {
        require(mintCounter < maxQuantity,"No more tokens with this ID to mint!"); //If less than 500 have been minted

        (uint256[] memory quantityArray, uint256 amountOfPasses) = dreampassContract.returnArrayOfOwnedPasses(msg.sender);
        if(amountOfPasses > 0){ //If user has a dreampass
            
            if(balanceOf(msg.sender,COMIC_ID) > 0){ //If user doesnt already have a discounted comic
                require(msg.value == priceToMintDiscounted, "You did not send enough eth to purchase a discounted comic!(or sent too much)");
                
                executeMintSequence();

                //CALL DREAMPASS TO BURN AND MINT NEW DREAMPASS
                dreampassContract.burnAndMintDreampass(msg.sender);

            } else{ //They already have a discounted comic, try to mint at full price, dont burn
                require(msg.value == priceToMintFull,"You did not send enough eth to purchase a full price comic!");
                require(balanceOf(msg.sender,COMIC_ID) < 3, "You have 3 comics already!");
               
                executeMintSequence();
            } 
        } else{ //user doesnt have dreampass
                require(msg.value == priceToMintFull,"You did not send enough eth to purchase a full price comic!");
                require(balanceOf(msg.sender,COMIC_ID) < 2, "You have 2 comics already! (get dreampass to be able to store 3)");

                executeMintSequence();
        }
    }

    function executeMintSequence() private {
        _mint(msg.sender, COMIC_ID, 1, "");
        mintCounter = SafeMath.add(mintCounter,1);
        emit AnnounceMint(msg.sender,COMIC_ID);
    }

}

//constructor() public ERC1155("https://bafybeibe3bbogcize5hgjjylszjq3vdgrxg3l3t422w4u4anvsnzditd74.ipfs.nftstorage.link/{id}.json"){
