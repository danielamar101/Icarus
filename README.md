

# Icarus

This repository is to store my implementation of Icarus. Was a good thought experiment to help flesh out all the little nuiances involved. 


#### Development environment

In order to test solidity contracts, we can just use the [Remix IDE](https://remix.ethereum.org/). It's simply a webapp so no need for a complex local environment. With it, you could debug, compile and deploy contracts to any nets, including mainnet. AND we can use it to create unit and integration tests using web3, chai or any javascript test framework.

Make sure you add your Etherscan API key and your github API key + credentials in order to be able to debug function calls and import contracts, respectively.

Also make sure you have your MetaMask wallet all set up and ready to go.


### Deploy Flow

![alt text](https://github.com/danielamar101/Icarus/blob/OctoberReArch/assets/DeploymentFlow.png)

### Deploy steps

<b>Note: We assume here your metadata and images have been uploaded to IPFS. I used [NFT.STORAGE](https://nft.storage/docs/how-to/mint-erc-1155/) to do this. If you dont want to go through all that trouble right now, I've included [the URIs](https://github.com/danielamar101/Icarus/blob/914aa14157e70f2698b7386ffc0c9454b0b98e51/Icarus.sol#L308-L309) I've created and used for testing at the bottom of the Icarus.sol file, which I will leave up. </b> 

1. Deploy dreampass contract
2. Deploy the comicKey contract with the following parameters:
    1. _dreampassAddress: the address of the dreampass contract you just created
    2. _contractURIString: The URI for the comicKeys
3. Deploy comic address with the following parameters:
    1. _comicId: the token ID of the comic
    2. _priceToMintDiscounted: 0 or .1 eth
    3. _priceToMintFull: .2 eth
    4. _comicKeyAddress: The address of the comicKey contract you just created
    5. _contractURI: Copy the uri commented at the bottom of the file. This will be used as the baseUri for all tokens and the collection metadata
4. Add the newly create comic contract's address to the state of the comicKey
    1. Call setComicAddress in the ComicKey contract
5. Deploy the moment contract with the following parameters:
    1. _momentId: the token ID of the moment
    2. _priceToMintDiscounted: 0 or .1 eth
    3. _priceToMintFull: .2 eth
    4. _comicAddress: The address of the comic contract you just created
    5. _contractURI: Copy the uri commented at the bottom of the file. This will be used as the baseUri for all tokens and the collection metadata
6. Mint a dreampass (mintDreampass)
7. Call deployRound in the comicKey Contract
    - Pass in an array of addresses and an array of lengths
    - NOTE: During testing I manually pass in an array of addresses that should be airdropped a comic key. When deployed to main we will use some sort of API to screenshot the blockchain and obtain the full array and size 
8. Going to [OpenSea's Testnet site](https://testnets.opensea.io/), you should be able to find the dreampass you just minted and a comicKey
9. Mint a comic (mintComic)
10. Repeat steps 3-5 as releases occur


### Next Steps

- Create mechanism for governing "Sale window"
    - Done, in the form of a saleIsActive flag. Pretty basic but does the trick
- Optimize this contract, as well as flesh out the governor contract to automate deployment.
- Create a full suite of unit and integration tests  
- Security audits

