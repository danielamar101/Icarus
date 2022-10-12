// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract DreamPass is ERC721, Ownable {
    using SafeMath for uint;

    uint256 DREAM_PASS_ID = 0;
    uint256 public maxQuantity = 500;
    uint256 public mintCounter = 0;

    address comicAddress;

    string public contractURIString;

    event AnnounceMint(address minter, uint id, uint count);

    //Create authentication around a comic book
    modifier onlyComic(address _address){
        if(comicAddress == _address){
            _;
        } else{
            revert("The comic must call this method!");
        }
    }

    constructor(string memory _contractURIString, string memory _name, string memory _symbol) ERC721(_name,_symbol) {
       
       contractURIString = _contractURIString;
    }

    function mintDreampass() external {
        require(mintCounter < maxQuantity, "All dreampasses have been minted!");
        require(balanceOf(msg.sender) == 0, "You already have a dreampass!");

        _mint(msg.sender, mintCounter);

        mintCounter = SafeMath.add(mintCounter,1);

        emit AnnounceMint(msg.sender,DREAM_PASS_ID, mintCounter);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return contractURIString;
    }

}

contract ComicKey is ERC1155, Ownable {
    using SafeMath for uint;
    
    DreamPass dreampassContract;
    address public dreampassAddress;

    string public contractURIString;

    uint256 public keyIdCount = 0;

    uint256 public mintCount = 0;
    uint256 public STANDARD_COMIC_KEY_QUANTITY = 500;

    event AnnounceComicRelease(string message, uint id);
    event AnnounceBurn(address burner, uint id);

    mapping(uint256 => address) public idToComicAddress;
    mapping(address => uint256) public comicAddressToId;

    mapping(uint256 => address) public idToMomentAddress;
    mapping(address => uint256) public momentAddressToid;

    //Temporary
    mapping(address => uint256) addressToQuantity;

    modifier onlyChildren(address _address){
        //Doubly linked list for O(1) access
        if(idToComicAddress[comicAddressToId[_address]] != address(0)){
            _;
        } 
        
    }
   
    constructor(address _dreampassAddress, uint256 _priceToMintDiscounted, uint256 _priceToMintFull, uint256 _momentPrice, string memory _name, string memory _symbol, string memory _contractURIString) 
    ERC1155(_contractURIString) {

        //Deploy a new comic book contract
        Comic newComic = new Comic(keyIdCount, _priceToMintDiscounted, _priceToMintFull, address(this), _name, _symbol, _contractURIString);

        address newComicAddress = address(newComic);

        //Add to comic record keeping
        idToComicAddress[keyIdCount] = newComicAddress;
        comicAddressToId[newComicAddress] = keyIdCount;

        //Deploy a new mintable moment contract
        Moment newMoment = new Moment(keyIdCount, _momentPrice, newComicAddress, _name, _symbol, _contractURIString);

        address newMomentAddress = address(newMoment);

        //Add to moment record keeping
        idToMomentAddress[keyIdCount] = newMomentAddress;
        comicAddressToId[newMomentAddress];

   
        keyIdCount++;

        //Sets the dreampass address to use as reference
        dreampassContract = DreamPass(_dreampassAddress);
        dreampassAddress = _dreampassAddress;


        contractURIString = _contractURIString;
    }

    function testShit() public view returns(address){
        return dreampassContract.ownerOf(0);
    }

    //Just to test snapshotting. Would probably make sense to have this off chain? Idk
    function snapshotDreampassState() public returns (address[] memory _allDreampassOwners, uint256[] memory _allDreampassQuantities){

        address[] memory allDreampassOwners = new address[];
        uint256[] memory allDreampassQuantities = new uint256[];
        uint256 arrayCounter = 0;

        //TODO: Kinda nasty, implement better
        for(uint256 i = 0; i < dreampassContract.mintCounter(); i++){
            address ownerAtIndex = dreampassContract.ownerOf(i);
            if(addressToQuantity[ownerAtIndex] == 0){
                allDreampassOwners[arrayCounter] = ownerAtIndex;
                arrayCounter++;
            }
            addressToQuantity[ownerAtIndex]++;

        }

        for(uint256 i = 0; i < arrayCounter; i++){
            allDreampassQuantities[i] = addressToQuantity[allDreampassOwners[i]];
        }

        return (allDreampassOwners, allDreampassQuantities);
    }


    function setDreamPassAddress(address _address) public onlyOwner {
        dreampassAddress = _address;
    }

    // This method will
    // 1. Instantiate a new comic book
    // 2. Instantiate a new mintable moment
    // 3. Airdrop by:
            // 1. minting <quantity> new tokens of id COMIC_KEY_ID
            // 2. transfer all these newly minted tokens to the addresses in the passed in array 
    // function deployRound(address[] memory allDreampassOwners,uint256[] memory allDreampassQuantities, uint256 _priceToMintDiscounted, uint256 _priceToMintFull, uint256 _momentPrice, string memory _name, string memory _symbol, string memory _contractURI) public onlyOwner(){
    //     require(allDreampassOwners.length == allDreampassQuantities.length, "Invalid size of airdrop arrays");

    //     Comic newComic = new Comic(keyIdCount, _priceToMintDiscounted, _priceToMintFull, address(this), _name, _symbol, _contractURI);

    //     address newComicAddress = address(newComic);

    //     //Add to comic record keeping
    //     idToComicAddress[keyIdCount] = newComicAddress;
    //     comicAddressToId[newComicAddress] = keyIdCount;

    //     //Create mintable moment
    //     Moment newMoment = new Moment(keyIdCount, _momentPrice, address(newComic), _name, _symbol, _contractURI);

    //     address newMomentAddress = address(newMoment);

    //     //Add to moment record keeping
    //     idToMomentAddress[keyIdCount] = newMomentAddress;
    //     comicAddressToId[newMomentAddress];

    //     //AIRDROP NEW COMIC KEYS

    //     //1. Mint 500 
    //     _mint(address(this),keyIdCount,STANDARD_COMIC_KEY_QUANTITY,"");

    //     //2. Transfer (Airdrop) comic keys to all dreampass holders
    //     for(uint256 i = 0; i < allDreampassOwners.length; i++){
    //         safeTransferFrom(address(this),allDreampassOwners[i],keyIdCount, allDreampassQuantities[i], "");
    //     }

    //     keyIdCount = SafeMath.add(keyIdCount,1);
    // }

    function burn(address _address, uint256 _comicId) public onlyChildren(msg.sender){
        _burn(_address, _comicId, 1);

        AnnounceBurn(_address, _comicId);
    }

    //Overrides ERC1155 standard method to be compatible with OpenSeas
    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId < keyIdCount);

        return string(
            abi.encodePacked(
                contractURIString,
                Strings.toString(_tokenId),".json"
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

    //Dev function
    function setContractURI(string memory _contractURI) public {
        contractURIString = _contractURI;
    }

}


contract Comic is ERC721, Ownable {
    using SafeMath for uint;

    uint256 COMIC_ID;
    uint256 mintCounter = 0;
    uint256 maxQuantity = 700;
    uint256 priceToMintDiscounted;
    uint256 priceToMintFull;

    address comicKeyAddress;
    ComicKey comicKeyContract;

    mapping(address => uint256) fullPriceMintCountPerAddress;

    event AnnounceMint(address minter, uint id);

    string contractURIString;

    constructor(uint256 _comicId, uint256 _priceToMintDiscounted, uint256 _priceToMintFull, address _comicKeyAddress, string memory _name, string memory _symbol, string memory _contractURIString) ERC721(_name,_symbol) {
        COMIC_ID = _comicId;
        priceToMintDiscounted = _priceToMintDiscounted;
        priceToMintFull = _priceToMintFull;
        comicKeyAddress = _comicKeyAddress;

        comicKeyContract = ComicKey(_comicKeyAddress);

        contractURIString = _contractURIString;
    }

    function mintComic() payable external {
        require(mintCounter < maxQuantity,"No more comics left to mint!"); 
        
        if(comicKeyContract.balanceOf(msg.sender,COMIC_ID) > 0){  //If person owns a comic key, mint at discounted rate
            require(msg.value == priceToMintDiscounted, "You did not send the right amount of eth to purchase a discounted comic!");
            executeMintSequence();

            //BURN COMIC KEY
            comicKeyContract.burn(msg.sender, COMIC_ID);

        } else{ //user doesnt have dreampass
            require(fullPriceMintCountPerAddress[msg.sender] < 2, "You have already minted 2 of these comics already!");
            require(msg.value == priceToMintFull,"You did not send enough eth to purchase a full price comic!");

            executeMintSequence();
            fullPriceMintCountPerAddress[msg.sender] += 1;
        }
    }

    function executeMintSequence() private {
        _mint(msg.sender, mintCounter);

        mintCounter = SafeMath.add(mintCounter,1);
        emit AnnounceMint(msg.sender,COMIC_ID);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return contractURIString;
    }

}

contract Moment is ERC721, Ownable {
    using SafeMath for uint;
    //TODO: Revisit storing moment ID as we can just have it link to a new URI
    uint256 MOMENT_ID;
    uint256 mintCounter = 0;
    uint256 maxQuantity = 50;
    uint256 priceToMint;
    address comicAddress;

    Comic comicContract;

    string contractURIString;

    event AnnounceMint(address minter, uint id);

    constructor(uint256 _momentId, uint256 _priceToMint, address _comicAddress, string memory _name, string memory _symbol, string memory _contractURIString) ERC721(_name,_symbol) {
        MOMENT_ID = _momentId;
        priceToMint = _priceToMint;

        comicAddress = _comicAddress;
        comicContract = Comic(_comicAddress);

        contractURIString = _contractURIString;
    }

    function mintMoment() payable external {
        require(mintCounter < maxQuantity,"No more comics left to mint!");
        require(balanceOf(msg.sender) == 0, "You can only own one mintable moment per a wallet!");
        require(comicContract.balanceOf(msg.sender) > 0, "You must own a comic to mint a moment!"); 
        require(msg.value == priceToMint, "You did not send the right amount of eth to purchase a moment!");

        _mint(msg.sender, mintCounter);

        mintCounter = SafeMath.add(mintCounter,1);
        emit AnnounceMint(msg.sender,MOMENT_ID);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return contractURIString;
    }

    // function tokenURI(uint256 tokenId) internal view override returns(string memory){
    //     return contractURIString;
    // }

}


//comic URI: https://bafybeic2ch5jfsbo3xsot6bzajf33phcqzca6gy4mqrvwcdgstvgrm4fdq.ipfs.nftstorage.link/
// mint pass URI: https://bafybeibwhojkw4szh6rzyxozpqo65e45vitaj4qbfsydicjal3iu75nlfa.ipfs.nftstorage.link/