

# Icarus

This repository is to store my implementation of Icarus. Was a good thought experiment to help Liran flesh out all the little nuiances involved. 


#### Development environment

In order to test solidity contracts, we can just use the [Remix IDE](https://remix.ethereum.org/). It's simply a webapp so no need for a complex local environment. With it, you could compile and deploy contracts to any nets, including mainnet.

Make sure you add your Etherscan API key and your github API key + credentials in order to be able to debug function calls and import contracts, respectively.

Also make sure you have your MetaMask wallet all set up and ready to go.


### Deploy steps

<b>Note: We assume here your metadata and images have been uploaded to IPFS. I used [NFT.STORAGE](https://nft.storage/docs/how-to/mint-erc-1155/) to do this</b>

1. Deploy dreampass contract
2. Deploy comic address with the following parameters:
    1. _id: Comic ID (first one is 1)
    2. _priceToMintDiscounted: 0 or .1 eth
    3. _priceToMintFull: .2 eth
    4. _maxQuantity: typically 700
    5. _dreampassAddress: copy the dreampass address from the contract created in the previous step
3. call dreampass contract's function addVerifiedContractAddress with the address of the newly instantiated comic and the comic id
4. Mint a dreampass
6. Going to [OpenSea's Testnet site](https://testnets.opensea.io/), you should be able to find the dreampass you just minted
7. Mint a comic
8. You should now be able to see the dreampass that follows the one you just minted in your "inventory" and the comic book you just minted.


### Next Steps

- Add mintable moments (WIP branch : addMintMoments, It's almost done, just havent given it a full test)
- Optimize this contract, as well as flesh out the governor contract to automate deployment. 
- Security audits

