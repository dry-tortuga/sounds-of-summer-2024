# Sounds Of Summer (08/28/2024)

The Sounds Of Summer collection features an audio medley of 5 quintessential summer bird songs and a unique visualization using Base Colors. They blend the ideas of Base Colors and Songbirdz, drawing inspiration from the [Soulbounds](https://github.com/apexethdev/Soulbounds) project created by [@0FJAKE](https://x.com/0FJAKE) and [@apex_ether](https://x.com/apex_ether).

Mint NFTs with an audio recording that is animated using an 8x8 grid of hex color codes.

The SVG images and HTML animations are generated on-chain and stored fully on-chain on Base.

The audio recording is stored on IPFS due to size limitations.

## Minting

- **Mint:** Mint at [mint.fun](https://mint.fun/base/0x06F2075d5a9f8Ca18f7FD13b4E18F78304eC2dC7) for 0.0001 ETH each
- **Mint as Songbirdz Holder:** Mint at [mint.fun](https://songbirdz.cc/sounds-of-summer-2024) for free if you are a Songbirdz holder. Snapshot taken at 08/28/2024 at 08:00 PM UTC. Limit of 1 NFT per address.
- **View on Opensea:** [Sounds of Summer 2024 Collection](https://opensea.io/collection/sounds-of-summer)
- **Contract on Base:** [View Contract on Basescan](https://basescan.org/address/0x06F2075d5a9f8Ca18f7FD13b4E18F78304eC2dC7)

## Songbirdz by drytortuga.base.eth
- [X](https://x.com/dry_tortuga) 
- [Warpcast](https://warpcast.com/dry-tortuga)
- [Website](https://songbirdz.cc)

## Base Colors by  Jake
- [X](https://x.com/@0FJAKE)
- [Warpcast](https://warpcast.com/jake)
- [Website](https://www.basecolors.com)

# Solidity

The ERC721A contract is in the `./contracts/SoundsOfSummer.sol` file.

Hardhat configuration for the contract is in the `./hardhat.config.js` file.

There are 2 scripts related to the ERC721 contract:

1. `./scripts/deployContract.js` can be used to deploy the contract to the local, test, and production environments.

2. `./scripts/generateAllowList.js` can be used to generate an allowlist (i.e. merkle tree) for the free mint function.

# HTML

The code for the HTML animation is in the `index.html` file with hardcoded variables for `tokenId`, `audioFileUrl`, and `audioFirstFrameBase64`.

You can open this file locally in order to test and make any changes as needed.

Once the HTML code is finalized, run it through a minimizer, and then store in the solidity contract!