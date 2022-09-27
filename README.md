

# Icarus

This repository is to store my implementation of Icarus. Was a good thought experiment to help Liran flesh out all the little nuiances involved. 


#### Development environment

In order to test solidity contracts, we can just use the [Remix IDE](https://remix.ethereum.org/). It's simply a webapp so no need for a complex local environment. With it, you could debug, compile and deploy contracts to any nets, including mainnet. AND we can use it to create unit and integration tests using web3, chai or any javascript test framework.

Make sure you add your Etherscan API key and your github API key + credentials in order to be able to debug function calls and import contracts, respectively.

Also make sure you have your MetaMask wallet all set up and ready to go.


### Deploy steps

<b>Note: We assume here your metadata and images have been uploaded to IPFS. I used [NFT.STORAGE](https://nft.storage/docs/how-to/mint-erc-1155/) to do this</b>

1. Deploy dreampass contract
2. Deploy comic address with the following parameters:
    1. _priceToMintDiscounted: 0 or .1 eth
    2. _priceToMintFull: .2 eth
    3. _dreampassAddress: copy the dreampass address from the contract created in the previous step
    4. _contractURI: copy the uri commented at the bottom of the file. This will be used as the baseUri for all tokens and the collection metadata
3. call dreampass contract's function addVerifiedContractAddress with the address of the newly instantiated comic and the comic id
4. Mint a dreampass
6. Going to [OpenSea's Testnet site](https://testnets.opensea.io/), you should be able to find the dreampass you just minted
7. Mint a comic with an id of 0
8. You should now be able to see the dreampass that follows the one you just minted in your "inventory" and the comic book you just minted.
9. Mint the next comic 
    1. _priceToMintDiscounted: 0 or .1 eth
    2. _priceToMintFull: .2 eth


### Next Steps

- Add mintable moments. This will require its own contract in order to have all of them be in the same collection(contract) on OpenSeas
- Create mechanism for governing "Sale window"
- Optimize this contract, as well as flesh out the governor contract to automate deployment.
- Create a full suite of unit and integration tests  
- Security audits

