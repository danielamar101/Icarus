// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract DreamPass is ERC1155, Ownable {
    using SafeMath for uint;

    uint256 public DREAM_PASS_ID = 0;
    uint256 public maxQuantity;
    uint256 public mintCounter;

    event AnnounceMint(address minter, uint id, uint count);

    constructor(uint256 _maxQuantity, uint256 _mintCounter, string memory _contractURI) ERC1155(_contractURI) {
        maxQuantity = _maxQuantity;
        mintCounter = _mintCounter;
    }

    function mintDreampass() external{
        require(mintCounter < maxQuantity, "All dreampasses have been minted!");
        require(balanceOf(msg.sender,0) == 0, "You already have a dreampass!");

        _mint(msg.sender, DREAM_PASS_ID,1,"");

        mintCounter = SafeMath.add(mintCounter,1);

        emit AnnounceMint(msg.sender,DREAM_PASS_ID, mintCounter);
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

    constructor(uint256 _id,uint256 _priceToMintDiscounted, uint256 _priceToMintFull, uint256 _maxQuantity, uint256 _mintCounter, 
    string memory _contractURI, address dreampassAddress) ERC1155(_contractURI) {
        COMIC_ID = _id;
        priceToMintDiscounted = _priceToMintDiscounted;
        priceToMintFull = _priceToMintFull;
        maxQuantity = _maxQuantity;
        mintCounter = _mintCounter;

        //Sets the address to use as reference
        dreampassContract = DreamPass(dreampassAddress);
    }

    function setDreamPassAddress(address _address) external onlyOwner {
        dreampassAddress = _address;
    }

    function mintComic() payable external {
        if(dreampassContract.balanceOf(msg.sender,0) == 1)

        if(balanceOf(msg.sender,DREAM_PASS_ID) == 1){ //If user has a dreampass
            if(balanceOf(msg.sender,id) == 0){ //If user doesnt already have a discounted comic
                require(msg.value == tokenIdToDiscountedPrice[id], "You did not send enough eth to purchase a discounted comic!(or sent too much)");
                require(tokenCounter[id] <= tokenMaxQuantity[id],"No more tokens with this ID to mint!"); //If less than 500 have been minted

                _mint(msg.sender, id,1,"");
                tokenCounter[id] = SafeMath.add(tokenCounter[id],1);
                emit AnnounceMint(msg.sender,id);

            } else{ //They already have a discounted comic, try to mint at full price
                require(msg.value == tokenIdToFullPrice[id],"You did not send enough eth to purchase a full price comic!");
                require(balanceOf(msg.sender,id) < 3, "You have 3 comics already!");
                require(tokenCounter[id] <= tokenMaxQuantity[id], "No more tokens with this ID to mint!");

                _mint(msg.sender, id, 1, "");
                tokenCounter[id] = SafeMath.add(tokenCounter[id],1);
                emit AnnounceMint(msg.sender,id);

            } 
        } else{ //user doesnt have dreampass
                require(msg.value == tokenIdToFullPrice[id],"You did not send enough eth to purchase a full price comic!");
                require(balanceOf(msg.sender,id) < 2, "You have more than 2 comics already!(Could have up to 3 if you have a dream pass)");
                require(tokenCounter[id] <= tokenMaxQuantity[id], "No more tokens with this ID to mint!");

                _mint(msg.sender, id, 1, "");
                tokenCounter[id] = SafeMath.add(tokenCounter[id],1);
                emit AnnounceMint(msg.sender,id);
        }



    }
}

contract IcarusOld is ERC1155, Ownable {

    using SafeMath for uint;

    // uint public constant MINT_PASS_1_COUNT = 50;
    // uint public constant MINT_PASS_2_COUNT = 50;
    // uint public constant MINT_PASS_3_COUNT = 50;
    // uint public constant MINT_PASS_4_COUNT = 50;

    uint256 public constant DREAM_PASS_ID = 0;
    uint256 public constant COMIC1_ID = 1;
    uint256 public constant COMIC2_ID = 2;
    uint256 public constant COMIC3_ID = 3;
    uint256 public constant COMIC4_ID = 4;


    mapping(uint => uint) public tokenMaxQuantity;

    mapping(uint => uint) public tokenCounter;

    mapping(uint => uint) public tokenIdToDiscountedPrice;
    mapping(uint => uint) public tokenIdToFullPrice;

    mapping(address => mapping(uint => uint)) public tokenMintCountPerAddress;
    
    uint public releasedComicsUpTo;

    event AnnounceComicRelease(string message, uint id);
    event AnnounceMint(address minter, uint id);

    constructor() public ERC1155("https://bafybeibe3bbogcize5hgjjylszjq3vdgrxg3l3t422w4u4anvsnzditd74.ipfs.nftstorage.link/{id}.json"){

        //Amount of each token we could mint
        tokenMaxQuantity[DREAM_PASS_ID] = 500;
        tokenMaxQuantity[COMIC1_ID] = 700;
        tokenMaxQuantity[COMIC2_ID] = 700;
        tokenMaxQuantity[COMIC3_ID] = 700;
        tokenMaxQuantity[COMIC4_ID] = 700;
        
        tokenCounter[DREAM_PASS_ID] = 0;
        tokenCounter[COMIC1_ID] = 0;
        tokenCounter[COMIC2_ID] = 0;
        tokenCounter[COMIC3_ID] = 0;
        tokenCounter[COMIC4_ID] = 0;

        //set prices to mint
        tokenIdToDiscountedPrice[DREAM_PASS_ID] = 0;
        tokenIdToDiscountedPrice[COMIC1_ID] = 0;
        tokenIdToDiscountedPrice[COMIC2_ID] = 100000000000000000; //.1 eth (in wei)
        tokenIdToDiscountedPrice[COMIC3_ID] = 100000000000000000;
        tokenIdToDiscountedPrice[COMIC4_ID] = 100000000000000000;

        tokenIdToFullPrice[COMIC1_ID] = 200000000000000000; // .2 eth in wei
        tokenIdToFullPrice[COMIC2_ID] = 200000000000000000;
        tokenIdToFullPrice[COMIC3_ID] = 200000000000000000;
        tokenIdToFullPrice[COMIC4_ID] = 200000000000000000;

        releasedComicsUpTo = 0;

    }

    // TODO: Fix to be onlyOwner can do this
    function releaseComic() public onlyOwner {
        if(releasedComicsUpTo < 4){
            releasedComicsUpTo += 1;
            emit AnnounceComicRelease("Comic has been released!",releasedComicsUpTo);
        }
    }

    function mintDreampass() external{
        require(tokenCounter[DREAM_PASS_ID] < tokenMaxQuantity[DREAM_PASS_ID], "All dreampasses have been minted!");
        require(balanceOf(msg.sender,0) == 0, "You already have a dreampass!");

        _mint(msg.sender, DREAM_PASS_ID,1,"");

        tokenCounter[DREAM_PASS_ID] = SafeMath.add(tokenCounter[0],1);
        tokenMintCountPerAddress[msg.sender][DREAM_PASS_ID] = 1;
        // emit TransferSingle(address(this),address(this),msg.sender,0,1);
        emit AnnounceMint(msg.sender,DREAM_PASS_ID);
    }
    
    modifier checkIdName(uint id){
        if(id == 1 || id == 2 || id == 3 || id == 4){
            _;
        } else{
            revert();
        }
    }

    //TODO: Discuss with liran implications of mint a comic and then selling it to another address of self and repeating to keep getting cheap comics
    function mintComic(uint id) payable external checkIdName(id){
        require(tokenMaxQuantity[id] != 0, "Invalid id entered!");
        require(id <= releasedComicsUpTo, "Comic isn't released yet!");
        require(id != 0, "Can't try to mint the dream pass!");

        if(balanceOf(msg.sender,DREAM_PASS_ID) == 1){ //If user has a dreampass
            if(balanceOf(msg.sender,id) == 0){ //If user doesnt already have a discounted comic
                require(msg.value == tokenIdToDiscountedPrice[id], "You did not send enough eth to purchase a discounted comic!(or sent too much)");
                require(tokenCounter[id] <= tokenMaxQuantity[id],"No more tokens with this ID to mint!"); //If less than 500 have been minted

                _mint(msg.sender, id,1,"");
                tokenCounter[id] = SafeMath.add(tokenCounter[id],1);
                emit AnnounceMint(msg.sender,id);

            } else{ //They already have a discounted comic, try to mint at full price
                require(msg.value == tokenIdToFullPrice[id],"You did not send enough eth to purchase a full price comic!");
                require(balanceOf(msg.sender,id) < 3, "You have 3 comics already!");
                require(tokenCounter[id] <= tokenMaxQuantity[id], "No more tokens with this ID to mint!");

                _mint(msg.sender, id, 1, "");
                tokenCounter[id] = SafeMath.add(tokenCounter[id],1);
                emit AnnounceMint(msg.sender,id);

            } 
        } else{ //user doesnt have dreampass
                require(msg.value == tokenIdToFullPrice[id],"You did not send enough eth to purchase a full price comic!");
                require(balanceOf(msg.sender,id) < 2, "You have more than 2 comics already!(Could have up to 3 if you have a dream pass)");
                require(tokenCounter[id] <= tokenMaxQuantity[id], "No more tokens with this ID to mint!");

                _mint(msg.sender, id, 1, "");
                tokenCounter[id] = SafeMath.add(tokenCounter[id],1);
                emit AnnounceMint(msg.sender,id);
        }



    }


}