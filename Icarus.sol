// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Governor is Ownable {

    DreamPass dreampassContract;
    // Comic[] comicContracts;
    Comic test;

    uint256 public maxQuantity = 500;
    uint256 public DREAM_PASS_ID = 0;
    uint256 public COMIC_ID = 1;
    uint256 public priceToMintDiscounted = 0;
    uint256 public priceToMintFull = 2;

    //     constructor(uint256 _id,uint256 _priceToMintDiscounted, uint256 _priceToMintFull, uint256 _maxQuantity,
    // string memory _contractURI, address _dreampassAddress) ERC1155(_contractURI) {
    constructor() payable {
        dreampassContract = new DreamPass();
        Comic aComic = new Comic(COMIC_ID,priceToMintDiscounted,priceToMintFull,maxQuantity,"Test2.com", address(dreampassContract));

        dreampassContract.addVerifiedContractAddress(address(aComic), COMIC_ID);
        dreampassContract.setDistinctPassQuantity(4); //4 dreampassesof different token ids
        test = aComic;

        dreampassContract.mintDreampass();

        aComic.mintComic();
        aComic.mintComic();
    }

    // function mintAComic(){

    // }
}

contract DreamPass is ERC1155, Ownable {
    using SafeMath for uint;

    //First dreampass
    uint256 public DREAM_PASS_ID = 0;

    uint256 public maxQuantity = 500;
    uint256 public mintCounter = 0;
    // string  public name = "Icarus Dreampass - Test";

    mapping(address => uint) comicAddressMap;
    mapping(uint => address) comicIdToAddressMap;

    uint public distinctPassCount = 4;

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


    constructor() ERC1155("https://bafybeihdk4hsaz6nghfhojiktrdtay2hcxduufmwc5sr2vz5jz6m5x4kue.ipfs.nftstorage.link/{id}.json") {
    }

    function addVerifiedContractAddress(address _address, uint256 _id) public onlyOwner {
        comicAddressMap[_address] = _id;
        comicIdToAddressMap[_id] = _address;
    }

    function mintDreampass() external {
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

        emit AnnounceBurn(msg.sender,idToBurn, 1);

        _mint(_playerAddress,idToBurn + 1, 1,"");
        emit AnnounceMint(msg.sender,idToBurn + 1, 1);
    }

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

    function getHighestOwnedDreampassId(address _address) public view returns (uint256) {
        (uint256[] memory quantityArray, uint256 amountOfPasses) = returnArrayOfOwnedPasses(_address);
        require(amountOfPasses > 0, "You don't have any passes!");

        uint256 counter = distinctPassCount;
        while(counter > 0){
            if(quantityArray[counter-1] > 0){
                return counter-1;
            }
            counter--;
        }
        //Unreachable (should be at least)
        return 0;
    }

    function setDistinctPassQuantity(uint256 _value) public onlyOwner{
        distinctPassCount = _value;
    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://bafybeihdk4hsaz6nghfhojiktrdtay2hcxduufmwc5sr2vz5jz6m5x4kue.ipfs.nftstorage.link/",
                Strings.toString(_tokenid),".json"
            )
        );
    }   

     function contractURI() public pure returns (string memory) {
        return "https://bafkreietsrxasxsrw6qdmitwjr3rnupsprfb5dmzxmf6jntb7bfsuhxdxi.ipfs.nftstorage.link/";
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

    mapping(address => uint256) fullPriceMintCountPerAddress;

    event AnnounceMint(address minter, uint id);
    event AnnounceComicRelease(string message, uint id);

    constructor(uint256 _id,uint256 _priceToMintDiscounted, uint256 _priceToMintFull, uint256 _maxQuantity,
    string memory _contractURI, address _dreampassAddress) ERC1155("https://bafybeigyrrxoaspbexvqcqhen2awdcgxvsvdfieovd7th6sieveos3vcli.ipfs.nftstorage.link/{id}.json") {
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

    //Only allows for a mint to occur if address has a dreampass id that is less than or equal to the comic id
    function isAllowedToMintWithDreampass(address _address) public view returns(bool){
        (uint256[] memory quantityArray, uint256 amountOfPasses) = dreampassContract.returnArrayOfOwnedPasses(_address);
        if(amountOfPasses == 0){
            return false;
        }

        uint256 counter = 0;
        while(counter <= COMIC_ID - 1){
            if(quantityArray[counter] > 0){
                return true;
            }
            counter++;
        }

        return false;
    }

    function mintComic() payable external {
        require(mintCounter < maxQuantity,"No more tokens with this ID to mint!"); //If less than 500 have been minted
        
        if(isAllowedToMintWithDreampass(msg.sender)){ //If user has a dreampass that is allowed to mint this comic
            require(msg.value == priceToMintDiscounted, "You did not send enough eth to purchase a discounted comic!(or sent too much)");
            executeMintSequence();

            //CALL DREAMPASS TO BURN AND MINT NEW DREAMPASS
            dreampassContract.burnAndMintDreampass(msg.sender);

        } else{ //user doesnt have dreampass
            require(fullPriceMintCountPerAddress[msg.sender] < 2, "You have already minted 2 of these comics already!");
            require(msg.value == priceToMintFull,"You did not send enough eth to purchase a full price comic!");

            executeMintSequence();
            fullPriceMintCountPerAddress[msg.sender] += 1;
        }
    }

    function executeMintSequence() private {
        _mint(msg.sender, COMIC_ID, 1, "");
        mintCounter = SafeMath.add(mintCounter,1);
        emit AnnounceMint(msg.sender,COMIC_ID);

    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://bafybeigyrrxoaspbexvqcqhen2awdcgxvsvdfieovd7th6sieveos3vcli.ipfs.nftstorage.link/",
                Strings.toString(_tokenid),".json"
            )
        );
    }   

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "https://bafybeigyrrxoaspbexvqcqhen2awdcgxvsvdfieovd7th6sieveos3vcli.ipfs.nftstorage.link/info",
                Strings.toString(COMIC_ID),".json"
            )
        );
    }

}

//constructor() public ERC1155("https://bafybeibe3bbogcize5hgjjylszjq3vdgrxg3l3t422w4u4anvsnzditd74.ipfs.nftstorage.link/{id}.json"){
