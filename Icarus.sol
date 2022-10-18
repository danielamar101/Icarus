// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DreamPass is ERC721, Ownable {
    using SafeMath for uint;
    string public contractURIString;

    uint256 public mintCounter = 0;
    uint256 public maxQuantity = 500;

    string ContractName = "MintPass";
    string ContractSymbol = "MP";

    address comicAddress;

    event AnnounceMint(address minter, uint id);

    constructor(string memory _contractURIString) ERC721(ContractName,ContractSymbol) {
       contractURIString = _contractURIString;
    }

    function mintDreampass() external {
        require(mintCounter < maxQuantity, "All dreampasses have been minted!");
        require(balanceOf(msg.sender) == 0, "You already have a dreampass!");

        uint256 currentMintCount = mintCounter;
        mintCounter = SafeMath.add(mintCounter,1);

        _mint(msg.sender, currentMintCount);

        emit AnnounceMint(msg.sender,currentMintCount);
    }

    // Retuns metadata of the comic collection, also for OpenSeas compatability
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
                contractURIString,
                "info.json")
            );
    }

    // Retuns metadata of each token, also for OpenSeas compatability
    // Since all dreampasses will be the same, same value is returned now
    function tokenURI(uint256 _tokenId) public override view returns(string memory){
        require(_tokenId < mintCounter, "Invalid token ID!");

        return string(
            abi.encodePacked(
                contractURIString,
                Strings.toString(0),
                ".json"
            )
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return contractURIString;
    }
}

contract ComicKey is ERC1155, Ownable {
    using SafeMath for uint;
    string public contractURIString;

    string public name = "Gate";
    string public symbol = "GATE";
    
    DreamPass dreampassContract;

    uint256 public keyIdCount = 0;

    uint256 public mintCount = 0;
    uint256 public STANDARD_COMIC_KEY_QUANTITY = 500;

    event AnnounceComicRelease(string message, uint id);
    event AnnounceBurn(address burner, uint id);

    mapping(uint256 => address) public idToComicAddress;
    mapping(address => uint256) public comicAddressToId;

    modifier onlyComic(address _address){
        //Doubly linked for O(1) access
        if(idToComicAddress[comicAddressToId[_address]] != address(0)){
            _;
        } 
    }
   
    constructor(address _dreampassAddress, string memory _contractURIString) 
    ERC1155(_contractURIString) {
        dreampassContract = DreamPass(_dreampassAddress);
        contractURIString = _contractURIString;
    }

    function setComicAddress(address _address, uint256 _keyId) public onlyOwner(){
        idToComicAddress[_keyId] = _address;
        comicAddressToId[_address] = _keyId; 
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    // Deploy new comic key
    // @requires: allDreampassOwners and allDreampassQuantities to be of the same length and obtained from a snapshot
    // 3. Airdrop by:
    //         1. minting <quantity> new tokens of id COMIC_KEY_ID
    //         2. transfer all these newly minted tokens to the addresses in the passed in array 
    function deployRound(address[] memory allDreampassOwners,uint256[] memory allDreampassQuantities) public onlyOwner(){
        require(allDreampassOwners.length == allDreampassQuantities.length, "Invalid");

        //AIRDROP NEW COMIC KEYS

        // 1. Mint 500 
        _mint(address(this),keyIdCount,STANDARD_COMIC_KEY_QUANTITY,"0x0");

        // 2. Transfer (Airdrop) comic keys to all dreampass holders
        for(uint256 i = 0; i < allDreampassOwners.length; i++){
            _safeTransferFrom(address(this),allDreampassOwners[i],keyIdCount, allDreampassQuantities[i], "");
        }

        keyIdCount = SafeMath.add(keyIdCount,1);
    }

    function burn(address _address, uint256 _comicId) public onlyComic(msg.sender){
        _burn(_address, _comicId, 1);

        emit AnnounceBurn(_address, _comicId);
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

    // //Dev function
    function setContractURI(string memory _contractURI) public onlyOwner(){
        contractURIString = _contractURI;
    }
}

contract Comic is ERC721, Ownable {
    using SafeMath for uint;
    string contractURIString;

    string ContractName = "Book";
    string ContractSymbol = "BOOK";

    //TODO: Revisit storing comic ID as we can just have each contract link to a new URI
    uint public COMIC_ID;
    uint public mintCounter = 0;
    uint public maxQuantity = 700;
    uint public priceToMintDiscounted;
    uint public priceToMintFull;

    ComicKey comicKeyContract;

    //set to true for dev purposes
    bool public saleIsActive = true;

    mapping(address => uint256) public fullPriceMintCountPerAddress;

    event AnnounceMint(address minter, uint id);

    constructor(uint256 _comicId, uint256 _priceToMintDiscounted, uint256 _priceToMintFull, address _comicKeyAddress, string memory _contractURIString) ERC721(ContractName,ContractSymbol) {
        COMIC_ID = _comicId;
        priceToMintDiscounted = _priceToMintDiscounted;
        priceToMintFull = _priceToMintFull;

        comicKeyContract = ComicKey(_comicKeyAddress);

        contractURIString = _contractURIString;
    }

    function mintComic() payable external {
        require(saleIsActive, "Sale window is not open!");
        require(mintCounter < maxQuantity,"No more comics left to mint!"); 
        
        if(comicKeyContract.balanceOf(msg.sender,COMIC_ID) > 0){  //If person owns a comic key, mint at discounted rate
            require(msg.value == priceToMintDiscounted, "You did not send the right amount of eth to purchase a discounted comic!");
            
            // BURN COMIC KEY
            comicKeyContract.burn(msg.sender, COMIC_ID);

            executeMintSequence();
        } else{ //user doesnt have comic key, mint at full price
            require(fullPriceMintCountPerAddress[msg.sender] < 2, "You have already minted 2 of these comics already!");
            require(msg.value == priceToMintFull,"You did not send enough eth to purchase a full price comic!");

            fullPriceMintCountPerAddress[msg.sender] = SafeMath.add(fullPriceMintCountPerAddress[msg.sender],1);

            executeMintSequence();
        }
    }

    function executeMintSequence() private {
        uint256 currentMintCount = mintCounter;
        mintCounter = SafeMath.add(mintCounter,1);

        _mint(msg.sender, currentMintCount);

        emit AnnounceMint(msg.sender,COMIC_ID);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    //Dev function
    function setContractURI(string memory _contractURI) public onlyOwner(){
        contractURIString = _contractURI;
    }

    // Retuns metadata of the comic collection, also for OpenSeas compatability
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
                contractURIString,
                "info.json")
            );
    }

    // Retuns metadata of each token, also for OpenSeas compatability
    function tokenURI(uint256 _tokenId) public override view returns(string memory){
        require(_tokenId < mintCounter, "Invalid token ID!");

        return string(
            abi.encodePacked(
                contractURIString,
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return contractURIString;
    }

}

contract Moment is ERC721, Ownable {
    using SafeMath for uint;
    string contractURIString;

    string ContractName = "Occasion";
    string ContractSymbol = "OCC";

    //TODO: Revisit storing moment ID as we can just have it link to a new URI
    uint256 public MOMENT_ID;
    uint256 public mintCounter = 0;
    uint256 public maxQuantity = 50;
    uint256 public priceToMint;

    Comic comicContract;

    //set to true for dev purposes
    bool public saleIsActive = true;

    event AnnounceMint(address minter, uint id);

    constructor(uint256 _momentId, uint256 _priceToMint, address _comicAddress, string memory _contractURIString) ERC721(ContractName,ContractSymbol) {
        MOMENT_ID = _momentId;
        priceToMint = _priceToMint;

        comicContract = Comic(_comicAddress);

        contractURIString = _contractURIString;
    }

    function mintMoment() payable external {
        require(saleIsActive, "Sale window is not open!");
        require(mintCounter < maxQuantity,"No more comics left to mint!");
        require(balanceOf(msg.sender) == 0, "You can only own one mintable moment per a wallet!");
        require(comicContract.balanceOf(msg.sender) > 0, "You must own a comic to mint a moment!"); 
        require(msg.value == priceToMint, "You did not send the right amount of eth to purchase a moment!");

        uint256 currentMintCount = mintCounter;
        mintCounter = SafeMath.add(mintCounter,1);

        _mint(msg.sender, currentMintCount);

        emit AnnounceMint(msg.sender,MOMENT_ID);
    }

    function flipSaleState() public onlyOwner() {
        saleIsActive = !saleIsActive;
    }

    function setComicAddress(address _address) public onlyOwner(){
        comicContract = Comic(_address);
    }

    //Dev function
    function setContractURI(string memory _contractURI) public onlyOwner(){
        contractURIString = _contractURI;
    }

    // Retuns metadata of the comic collection, also for OpenSeas compatability
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
                contractURIString,
                "info.json")
            );
    }

    // Retuns metadata of each token, also for OpenSeas compatability
    function tokenURI(uint256 _tokenId) public override view returns(string memory){
        require(_tokenId < mintCounter, "Invalid token ID!");

        return string(
            abi.encodePacked(
                contractURIString,
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return contractURIString;
    }
}

// Code Words
// Dreampass = MintPass
// Comic = Book
// Key = Gate
// Moment = Occasion

// MintPass URI: https://bafybeidablwsufbcgqtswo7vxjc7ujdiy5atn7yeopoth46vlzpizfahbi.ipfs.nftstorage.link/
// Book URI: https://bafybeicprpl5yqzqyylk7jb2ipup6jywsxaek7mdjz6ggz7gox76hr3pom.ipfs.nftstorage.link/
// Gate URI: https://bafybeigait6ojhforlrr55lgv4vvn2rplavrbm6yihfik55zxu4vlweaey.ipfs.nftstorage.link/
// Occasion URI: https://bafybeiaa4coi6nmkeancsjuw3j25qlv6xf6n2c3qjjc2qccccz7dzpcf2e.ipfs.nftstorage.link/
