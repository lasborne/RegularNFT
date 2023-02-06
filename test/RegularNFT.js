
const {ethers} = require('hardhat')
const {expect} = require('chai')

describe('NFT Contract', () => {
    let deployer, nftContract, user1, user2, user3

    beforeEach(async() => {
        [deployer, user1, user2, user3] = await ethers.getSigners()

        const NftContract = await ethers.getContractFactory('RegularNFT', deployer)
        nftContract = await NftContract.deploy()

    })

    describe('runs the NFT smart contract', () => {
        it('returns the BaseUri', async() => {
            const baseURI = await nftContract.baseURI()
            expect(baseURI).to.equal(
                'https://ipfs.io/ipfs/QmSrSwboxekwhUfK5nKcbzK6xuTmNxhsiz643pmjqJfqPt/'
            )
        })
        it('allows a random user to mint', async() => {
            
            let balanceBefore = await ethers.provider.getBalance(deployer.address)
            let valueSent = ethers.utils.parseEther('0.005')
            console.log(`Before: ${balanceBefore}`)

            await nftContract.connect(user1).mint('0x', 1, {value: valueSent})

            let balanceNow = await ethers.provider.getBalance(deployer.address)
            let total = Number(balanceBefore) + Number(valueSent)
            console.log(`After: ${balanceNow}`)
            console.log(`Sum: ${total} ETH`)
            
            expect(await nftContract.balanceOf(user1.address)).to.equal(1)
            console.log(await nftContract.ownerOf(1))

            // Transfer NFT from user1 to user2
            await nftContract.connect(user1).transferTo(user2.address, 1)

            // User2 mints the NFT of tokenId 4
            await nftContract.connect(user2).mint('0x', 4, {value: valueSent})
            // Expect the balance of user2 to be 2 NFTs because user1 sent 1, and user2 minted 1
            expect(await nftContract.balanceOf(user2.address)).to.eq(2)
            // User3 mints the NFT of tokenId 6
            await nftContract.connect(user3).mint('0x', 6, {value: valueSent})
            // Expect user3 balance to be 1
            expect(await nftContract.balanceOf(user3.address)).to.eq(1)

            // Expect the array to contain 3 elements since only 3 nfts were minted
            expect((await nftContract.allMintsShow()).length).to.eq(3)
            console.log(await nftContract.allMintsShow())
        })
    })
})