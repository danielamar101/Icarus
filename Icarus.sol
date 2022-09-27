// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


//WIP. Does not work in current state.
//The idea with this is to automate the manual labor required to deploy this project, and removing the potential for errors.
contract Governor is Ownable {

    DreamPass dreampassContract;
    // Comic[] comicContracts;
    Comic test;

    uint256 public maxQuantity = 500;
    uint256 public DREAM_PASS_ID = 0;
    uint256 public COMIC_ID = 1;
    uint256 public priceToMintDiscounted = 0;
    uint256 public priceToMintFull = 2;

    constructor() payable {
        // dreampassContract = new DreamPass();
        // Comic aComic = new Comic(COMIC_ID,priceToMintDiscounted,priceToMintFull,maxQuantity,"Test2.com", address(dreampassContract));

        // dreampassContract.addVerifiedContractAddress(address(aComic), COMIC_ID);
        // dreampassContract.setDistinctPassQuantity(4); //4 dreampassesof different token ids
        // test = aComic;

        // dreampassContract.mintDreampass();

        // aComic.mintComic();
        // aComic.mintComic();
    }



}

contract DreamPass is ERC1155, Ownable {
    using SafeMath for uint;

    //First dreampass
    uint256 public DREAM_PASS_ID = 0;

    uint256 public maxQuantity = 500;
    uint256 public mintCounter = 0;
    // string  public name = "Icarus Dreampass - Test";

    address comicAddress;

    string public contractURIString;

    uint public distinctPassCount = 4;

    event AnnounceMint(address minter, uint id, uint count);
    event AnnounceBurn(address burner, uint id, uint count);

    //Create authentication around a comic book
    modifier onlyComic(address _address){
        if(comicAddress == _address){
            _;
        } else{
            revert("The comic must call this method!");
        }
    }


    constructor(string memory _contractURIString) ERC1155(_contractURIString) {
        contractURIString = _contractURIString;
    }

    //Allows the dreampass to add verified comic addresses and map them to an ID
    function addVerifiedContractAddress(address _address) public onlyOwner {
        comicAddress = _address;
    }

    function mintDreampass() external {
        require(mintCounter < maxQuantity, "All dreampasses have been minted!");
        require(balanceOf(msg.sender,0) == 0, "You already have a dreampass!");

        _mint(msg.sender, DREAM_PASS_ID,1, "");

        mintCounter = SafeMath.add(mintCounter,1);

        emit AnnounceMint(msg.sender,DREAM_PASS_ID, mintCounter);
    }

    //Should only be called from the comic during discounted minting. Hence the modifier.
    function burnAndMintDreampass(address _playerAddress, uint256 _id) external onlyComic(msg.sender){
        //Determine if player owns any dreampass
        uint256 idToBurn = getHighestOwnedDreampassId(_playerAddress, _id);
        _burn(_playerAddress,idToBurn, 1);

        emit AnnounceBurn(msg.sender,idToBurn, 1);

        _mint(_playerAddress,idToBurn + 1, 1,"");
        emit AnnounceMint(msg.sender,idToBurn + 1, 1);
    }

    // Returns a tuple of information on owned dreampasses
    /* 
    * @param _address: Address to query information on
    * @returns:
    *   - _quantityArray: An array where each index represents a dreampass and each value at an index represents quantity of that dreampass
    *   - _amountOfPasses: Total quantity of owned passes
    */
    function returnArrayOfOwnedPasses(address _address) public view returns (uint256[] memory _quantityArray, uint256 _amountOfPasses){
        uint256 dreampassIdCounter = 0;
        uint256[] memory quantityArray = new uint256[](distinctPassCount);
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
        (, uint256 amountOfPasses) = returnArrayOfOwnedPasses(_address);

        if(amountOfPasses > 0){
            return true;
        } else{
            return false;
        }
    }

    //Returns the dreampass with the highest token id. This is how we choose which dreampass to burn if a user obtains multiple off the secondary market.
    function getHighestOwnedDreampassId(address _address, uint256 _tokenId) public view returns (uint256) {
        (uint256[] memory quantityArray, uint256 amountOfPasses) = returnArrayOfOwnedPasses(_address);
        require(amountOfPasses > 0, "You don't have any passes!");

        uint256 counter = _tokenId;
        while(counter > 0){
            if(quantityArray[counter-1] > 0){
                return counter-1;
            }
            counter--;
        }

        //Unreachable due to first require statement
        return 0;
    }

    //To set how many different dreampass tokens there are
    function setDistinctPassQuantity(uint256 _value) public onlyOwner{
        distinctPassCount = _value;
    }

    //Overrides ERC1155 standard method to be compatible with OpenSeas
    function uri(uint256 _tokenid) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                contractURIString,
                Strings.toString(_tokenid),".json"
            )
        );
    }   

    // Retuns metadata of the comic collection, also for OpenSeas compatability
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
                contractURIString,
                "info.json")
            );
    }

}

contract Comic is ERC1155, Ownable {
    using SafeMath for uint;

    struct ComicStruct {
        uint256 COMIC_ID;
        uint256 priceToMintDiscounted;
        uint256 priceToMintFull;
        uint256 maxQuantity;
        uint256 mintCounter;
    }
    
    ComicStruct[] Comics;
    DreamPass dreampassContract;
    address public dreampassAddress;

    string public contractURIString;
    string public baseTokenURIString;

    uint256 public comicCount = 0;
    uint256 public STANDARD_COMIC_QUANTITY = 700;

    mapping(address => uint256) fullPriceMintCountPerAddress;

    event AnnounceMint(address minter, uint id);
    event AnnounceComicRelease(string message, uint id);

    constructor(uint256 _priceToMintDiscounted, uint256 _priceToMintFull,
    address _dreampassAddress, string memory _contractURIString) 
    ERC1155(_contractURIString) {
   
        Comics.push(ComicStruct(comicCount, _priceToMintDiscounted, _priceToMintFull,STANDARD_COMIC_QUANTITY,0)); 

        comicCount++;

        //Sets the dreampass address to use as reference
        dreampassContract = DreamPass(_dreampassAddress);
        dreampassAddress = _dreampassAddress;

        contractURIString = _contractURIString;
    }

    function deployComic(uint256 _priceToMintDiscounted, uint256 _priceToMintFull) public onlyOwner {
        Comics.push(ComicStruct(comicCount, _priceToMintDiscounted, _priceToMintFull,STANDARD_COMIC_QUANTITY,0));  

        comicCount++;
 } 


    function setDreamPassAddress(address _address) external onlyOwner {
        dreampassAddress = _address;
    }

    //Only allows for a mint to occur if address has a dreampass id that is less than or equal to the comic id
    function isAllowedToMintWithDreampass(address _address) public view returns(bool){
        (uint256[] memory quantityArray, uint256 amountOfPasses) = dreampassContract.returnArrayOfOwnedPasses(_address);
        if(amountOfPasses == 0){
            return false;
        }

        uint256 counter = 0;
        while(counter <= comicCount - 1){
            if(quantityArray[counter] > 0){
                return true;
            }
            counter++;
        }

        return false;
    }

    function mintComic(uint256 _tokenId) payable external {
        require(_tokenId < comicCount);
        require(Comics[_tokenId].mintCounter < Comics[_tokenId].maxQuantity,"No more comics left to mint!"); 
        
        if(isAllowedToMintWithDreampass(msg.sender)){ 
            require(msg.value == Comics[_tokenId].priceToMintDiscounted, "You did not send the right amount of eth to purchase a discounted comic!");
            executeMintSequence(Comics[_tokenId].COMIC_ID);

            //CALL DREAMPASS TO BURN AND MINT NEW DREAMPASS
            dreampassContract.burnAndMintDreampass(msg.sender, _tokenId);

        } else{ //user doesnt have dreampass
            require(fullPriceMintCountPerAddress[msg.sender] < 2, "You have already minted 2 of these comics already!");
            require(msg.value == Comics[_tokenId].priceToMintFull,"You did not send enough eth to purchase a full price comic!");

            executeMintSequence(Comics[_tokenId].COMIC_ID);
            fullPriceMintCountPerAddress[msg.sender] += 1;
        }
    }

    function executeMintSequence(uint256 _tokenId) private {
        _mint(msg.sender, _tokenId, 1, "");

        Comics[_tokenId].mintCounter = SafeMath.add(Comics[_tokenId].mintCounter,1);
        emit AnnounceMint(msg.sender,_tokenId);

    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId < comicCount);

        return string(
            abi.encodePacked(
                contractURIString,
                Strings.toString(_tokenId),".json"
            )
        );
    }   

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                contractURIString,
                "info.json"
            )
        );
    }

    //Dev function
    function setContractURI(string memory _contractURI) public {
        contractURIString = _contractURI;
    }


}


//comic URI: https://bafybeic2ch5jfsbo3xsot6bzajf33phcqzca6gy4mqrvwcdgstvgrm4fdq.ipfs.nftstorage.link/
// mint pass URI: https://bafybeibwhojkw4szh6rzyxozpqo65e45vitaj4qbfsydicjal3iu75nlfa.ipfs.nftstorage.link/