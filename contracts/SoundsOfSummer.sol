// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title SoundsOfSummer - A combination of concepts from Base Colors and Songbirdz.
 * @notice drytortuga.base.eth x 0FJAKE.eth collaboration
 * @dev Mint NFTs with an audio recording that is animated using 8x8 grid of hex color codes.
 * @dev The SVG images and HTML animations are generated on-chain and stored fully on-chain on Base.
 * @dev The audio recording is stored on IPFS due to size limitations.
 */
interface IBaseColors {
	function getAttributesAsJson(uint256 tokenId) external view returns (string memory);

	struct ColorData {
		uint256 tokenId;
		bool isUsed;
		uint256 nameChangeCount;
		string[] modifiableTraits;
	}

	function getColorData(string memory color) external view returns (ColorData memory);
}

contract SoundsOfSummer is ERC721A, Ownable, ReentrancyGuard {

	// Hardcode the mint price
	uint256 private constant MINT_PRICE = 0.0001 ether;

	// Hardcode the maximum number of mints allowed
	uint256 private constant MAX_NUM_MINTED = 65536;

	// Keep track of the hex symbols
	bytes private constant HEX_SYMBOLS = "0123456789abcdef";

	// Hardcode the html body for the animation
	string private constant HTML_BODY = '<body id=body><div><canvas id=canvas width=800px height=800px></canvas><audio id=audio><source id=source-ogg src="" type=audio/ogg><source id=source-wav src="" type=audio/wav><source id=source-mp3 src="" type=audio/mp3></audio></div><script>var e=base64ToHex(audioFirstFrameBase64),t="0123456789abcdef",a=document.getElementById("body"),n=document.getElementById("canvas"),r=document.getElementById("audio"),o=document.getElementById("source-ogg"),d=document.getElementById("source-wav"),i=document.getElementById("source-mp3"),u=n.getContext("2d"),s=0,c="736730",l="ACA292",m="D06809",g="EA453A",f="18303A",b=new Array(64);function drawBoardFrame(e,t){for(let r=0;r<8;r++)for(let o=0;o<8;o++){var a=t+6*r+48*o,n=b[8*o+r];if(!n)n=hashColorCode(e.slice(a,a+6),tokenId,a);u.clearRect(100*r,100*o,100,100),u.fillStyle="#"+n,u.fillRect(100*r,100*o,100,100)}}function drawBoard(e){requestAnimationFrame((function animate(){drawBoardFrame(e,s),requestAnimationFrame(animate)}));setInterval((function changeColor(){(s+=384)+384>e.length&&(s=0)}),47.3294987675)}function buf2hex(e){return[...new Uint8Array(e)].map((e=>e.toString(16).padStart(2,"0"))).join("")}function buf2base64(e){for(var t="",a=new Uint8Array(e),n=a.byteLength,r=0;r<n;r++)t+=String.fromCharCode(a[r]);return btoa(t)}function base64ToHex(e){for(var t=atob(e),a="",n=0;n<t.length;n++){var r=t.charCodeAt(n).toString(16);a+=2===r.length?r:"0"+r}return a.toUpperCase()}function hashColorCode(e,a,n){var r=BigInt(Number(`0x${e}`)+a+n);r=(r=((r=(r>>BigInt(16)^r)*BigInt(73244475))>>BigInt(16)^r)*BigInt(73244475))>>BigInt(16)^r,r=Number(r%BigInt(16777216));for(var o="",d=0;d<6;d++){o+=t[r>>4*d&15]}return o}b[18]=f,b[19]=c,b[20]=l,b[21]=f,b[26]=l,b[27]=m,b[28]=g,b[29]=c,b[34]=c,b[35]=g,b[36]=m,b[37]=l,b[42]=f,b[43]=l,b[44]=c,b[45]=f,drawBoardFrame(e,0),a.addEventListener("click",(e=>{var t=new XMLHttpRequest;t.open("GET",audioFileUrl,!0),t.responseType="arraybuffer",t.onload=function(){const e=buf2hex(t.response),a=buf2base64(t.response);o.src="data:audio/ogg;base64,"+a,d.src="data:audio/wav;base64,"+a,i.src="data:audio/mp3;base64,"+a,r.loop=!0,r.load(),drawBoard(e),r.play()},t.send()}));</script></body>';

	// Hardcode the start of the svg for the image
	string private constant SVG_START = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800" width="800" height="800"><rect width="800" height="800" fill="#000000"/>';

	// Hardcode the end of the svg for the image
	string private constant SVG_END = '</svg>';

	// Hardcode the first frame (i.e. 8x8 grid) of the audio hex data
	bytes private constant AUDIO_FIRST_FRAME_HEX = hex"49443304000000000022545353450000000e0000034c61766636312e342e3130300000000000000000000000fffb50000000000000000000000000000000000000000000000000000000000000000000496e666f0000000f0000015b00008e72000406090b0e101316181b1e202325282a2c2f313437393c3f414446494b4e505355585a5d606265676a6c6f717476797b7e818386888b8d909295979a9c9fa2a5a7aaacaeb1b3b6b8bbbdc0c3c6c8cbcdd0d2d5d7d9dcdee1e4e7e9eceef1f3";

	// Store onchain the merkle tree hash of the allowlist for songbirdz owners
	bytes32 private merkleTreeRoot;

	// Set the current audio file URL from ipfs
	string private audioFileUrl;

	// Keep track of the contract address for Base Colors
	address private immutable baseColorsAddress;
	IBaseColors private immutable baseColors;

	// Create a predefined 4x4 grid at the center of of the 8x8 color grid

	string private constant BIRD_1_HEX = '736730'; // Ovenbird
	string private constant BIRD_2_HEX = 'ACA292'; // Hermit Thrush
	string private constant BIRD_3_HEX = 'D06809'; // American Robin
	string private constant BIRD_4_HEX = 'EA453A'; // Pileated Woodpecker
	string private constant BIRD_5_HEX = '18303A'; // Common Loon

	mapping(uint256 => string) private lockedColors;

	mapping(address => bool) private hasMinted;

	constructor() Ownable(msg.sender) ERC721A("SoundsOfSummer", "SOUNDS_OF_SUMMER") {

		baseColorsAddress = 0x7Bc1C072742D8391817EB4Eb2317F98dc72C61dB; // Base
		baseColors = IBaseColors(baseColorsAddress);

		lockedColors[18] = BIRD_5_HEX;
		lockedColors[19] = BIRD_1_HEX;
		lockedColors[20] = BIRD_2_HEX;
		lockedColors[21] = BIRD_5_HEX;
		lockedColors[26] = BIRD_2_HEX;
		lockedColors[27] = BIRD_3_HEX;
		lockedColors[28] = BIRD_4_HEX;
		lockedColors[29] = BIRD_1_HEX;
		lockedColors[34] = BIRD_1_HEX;
		lockedColors[35] = BIRD_4_HEX;
		lockedColors[36] = BIRD_3_HEX;
		lockedColors[37] = BIRD_2_HEX;
		lockedColors[42] = BIRD_5_HEX;
		lockedColors[43] = BIRD_2_HEX;
		lockedColors[44] = BIRD_1_HEX;
		lockedColors[45] = BIRD_5_HEX;

	}

	/*----------------------------- OnlyOwner ---------------------*/

	/**
	 * @dev Only callable by the contract owner.
	 */
	function publicWithdraw() external onlyOwner nonReentrant {

		(bool success,) = msg.sender.call{value: address(this).balance}("");
		require(success, "Transfer failed.");

	}

	/**
	 * @dev Only callable by the contract owner.
	 */
	function publicSetMerkleTreeRoot(bytes32 hash) external onlyOwner {
		merkleTreeRoot = hash;
	}

	/**
	 * @dev Only callable by the contract owner.
	 */
	function publicSetAudioFileUrl(string memory newURL) external onlyOwner {
		audioFileUrl = newURL;
	}

	/*----------------------------- Public ------------------------*/

	/**
	 * @dev Used to mint an arbitary quantity of NFTs, costing 0.0001 ETH each.
	 */
	function publicMint(uint256 quantity) external payable nonReentrant {

		require(quantity > 0 && quantity <= 25, "Max amount to mint is 25");
		require((MINT_PRICE * quantity) == msg.value, "Incorrect ETH value sent");

		if ((_nextTokenId() + quantity) < MAX_NUM_MINTED) {
			_safeMint(msg.sender, quantity);
		}

	}

	/**
	 * @dev Used by Songbirdz holders to mint 1 NFT for free.
	 */
	function publicSongbirdzMint(bytes32[] calldata proof) external nonReentrant {

		require(!hasMinted[msg.sender], "Already minted 1 NFT");
		require(_verifyAllowListProof(proof), "Not in the allowlist");

		if (_nextTokenId() < MAX_NUM_MINTED) {

			hasMinted[msg.sender] = true;
			_safeMint(msg.sender, 1);

		}

	}

	/**
	 * @dev Get the current URL for the audio file.
	 */
	function publicGetAudioFileUrl() external view returns (string memory) {
		return audioFileUrl;
	}

	/**
	 * @dev tokenURI override to return JSON metadata with
	 *      SVG image, HTML animation, and JSON attributes.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {

		require(_exists(tokenId), "Token does not exist");

		// Get SVG data
		string memory svg = publicBuildSVG(tokenId);

		// Encode SVG data to Base64
		string memory svgBase64 = Base64.encode(bytes(svg));

		// Get HTML data
		string memory html = publicBuildHTML(tokenId);

		// Encode HTML data to base64
		string memory base64HTML = Base64.encode(bytes(html));

		// Get JSON attributes
		string memory attributes = publicBuildAttributesJSON(tokenId);

		// Build JSON metadata
		string memory json = string(
			abi.encodePacked(
				'{"name":"SoundsOfSummer #',
				Strings.toString(tokenId),
				'","description":"The Sounds Of Summer collection features an audio medley of 5 quintessential summer bird songs and a unique visualization using Base Colors."',
				',"attributes":',
				attributes,
				',"image":"data:image/svg+xml;base64,',
				svgBase64,
				'","animation_url":"data:text/html;base64,',
				base64HTML,
				'"}'
			)
		);

		// Encode JSON data to Base64
		string memory jsonBase64 = Base64.encode(bytes(json));

		// Construct final URI
		return string(abi.encodePacked("data:application/json;base64,", jsonBase64));

	}

	/**
	 * @dev Build the SVG image for the NFT. Handy for front-end / testing.
	 */
	function publicBuildSVG(uint256 tokenId) public view returns (string memory) {

		require(_exists(tokenId), "Token does not exist");

		string memory svg = _tokenToSVG(tokenId);

		return svg;

	}

	/**
	 * @dev Build the HTML animation for the NFT. Handy for front-end / testing.
	 */
	function publicBuildHTML(uint256 tokenId) public view returns (string memory) {

		require(_exists(tokenId), "Token does not exist");

		string memory html = _tokenToHTML(tokenId);

		return html;

	}

	/**
	* @dev Build the JSON attributes for the NFT. Handy for front-end / testing.
	*/
	function publicBuildAttributesJSON(uint256 tokenId) public view returns (string memory) {

		require(_exists(tokenId), "Token does not exist");

		// Get the names from the Base Colors contract for the 5 bird hex colors

		string memory name1 = _getColorName(BIRD_1_HEX);
		string memory name2 = _getColorName(BIRD_2_HEX);
		string memory name3 = _getColorName(BIRD_3_HEX);
		string memory name4 = _getColorName(BIRD_4_HEX);
		string memory name5 = _getColorName(BIRD_5_HEX);

		string memory attributes = string(
			abi.encodePacked(
				"[",
				'{"trait_type":"Color 1","value":"',
				name1,
				'"},{"trait_type":"Color 2","value":"',
				name2,
				'"},{"trait_type":"Color 3","value":"',
				name3,
				'"},{"trait_type":"Color 4","value":"',
				name4,
				'"},{"trait_type":"Color 5","value":"',
				name5,
				'"}]'
			)
		);

		return attributes;

	}

	/*----------------------------- Private ------------------------*/

	/**
	 * @dev Build the SVG image for the NFT,
	 *      i.e. the first 8x8 grid frame of the animation.
	 */
	function _tokenToSVG(uint256 tokenId) internal view returns (string memory) {

		string memory svgContent = SVG_START;
		bytes memory audioContent = AUDIO_FIRST_FRAME_HEX;

		// Loop through first 384 hex characters in audio file

		for (uint256 i = 0; i < 8; i++) {

			for (uint256 j = 0; j < 8; j++) {

				// Get the position of the square in the 8x8 grid
				uint256 gridIdx = i + (j * 8);

				string memory finalColor;

				// Check if this square in the grid is a locked color
				if(bytes(lockedColors[gridIdx]).length != 0) {

					finalColor = lockedColors[gridIdx];

				} else {

					// Get the start index for the 6 hex chars at the current
					// position in the audio file, i.e. the current color
					uint256 hexStartIdx = (i * 3) + (j * 24);

					// Convert those 6 hex chars to decimal
					uint256 audioPiece =
						(uint256(uint8(audioContent[hexStartIdx + 2]))) +
						((uint256(uint8(audioContent[hexStartIdx + 1]))) << 8) +
						((uint256(uint8(audioContent[hexStartIdx]))) << 16);

					// Convert the 6 hex color code into a random hash
					// and then parse back to 6 hex color code
					finalColor = _hashColorCode(audioPiece, tokenId, hexStartIdx * 2);

				}

				svgContent = string(
					abi.encodePacked(
						svgContent,
						'<rect x="',
						Strings.toString(i * 100),
						'" y="',
						Strings.toString(j * 100),
						'" width="100" height="100" fill="#',
						finalColor,
						'" />'
					)
				);

			}

		}

		return string(abi.encodePacked(svgContent, SVG_END));

	}

	/**
	 * @dev Build the HTML for the NFT,
	 *      i.e an animation of the 8x8 grid that follows the audio content.
	 */
	function _tokenToHTML(uint256 tokenId) internal view returns (string memory) {

		return string(
			abi.encodePacked(
				"<html><head><script>",
				"var tokenId=",
				Strings.toString(tokenId),
				",audioFileUrl='",
				audioFileUrl,
				"',audioFirstFrameBase64='",
				Base64.encode(AUDIO_FIRST_FRAME_HEX),
				"';</script>",
				"<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'><style type='text/css'>html{height:100%;width:100%}body{height:100%;width:100%;margin:0;padding:0}canvas{display:block;max-width:100%;max-height:100%;padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0;object-fit:contain;}</style>",
				"</head>",
				HTML_BODY,
				"</html>"
			)
		);

	}

	/**
	 * @dev Check if this color has a name in the baseColors contract.
	 */
	function _getColorName(string memory colorhex) internal view returns (string memory) {

		// Concatenate "#" with the colorhex
		string memory colorWithHash = string(abi.encodePacked("#", colorhex));

		try baseColors.getColorData(colorWithHash) returns (IBaseColors.ColorData memory colorData) {

			// Start finding the color name
			// Get the attributes JSON string for the color
			string memory attributes = baseColors.getAttributesAsJson(colorData.tokenId);

			// Extracting the color name from the attributes JSON string
			bytes memory attributesBytes = bytes(attributes);
			bytes memory colorNameKey = bytes('"trait_type":"Color Name","value":"');
			bytes memory endKey = bytes('"}');

			// Finding the start position of the color name
			uint256 start = 0;

			for (uint256 i = 0; i < attributesBytes.length - colorNameKey.length; i++) {

				bool ismatched = true;

				for (uint256 j = 0; j < colorNameKey.length; j++) {

					if (attributesBytes[i + j] != colorNameKey[j]) {
						ismatched = false;
						break;
		
					}

				}

				if (ismatched) {
					start = i + colorNameKey.length;
					break;
				}
			}

			// Finding the end position of the color name
			uint256 end = start;

			for (uint256 i = start; i < attributesBytes.length - endKey.length; i++) {

				bool ismatched = true;

				for (uint256 j = 0; j < endKey.length; j++) {

					if (attributesBytes[i + j] != endKey[j]) {
						ismatched = false;
						break;
					}

				}
				
				if (ismatched) {
					end = i;
					break;
				}

			}

			// Extracting the color name
			bytes memory colorNameBytes = new bytes(end - start);

			for (uint256 i = 0; i < end - start; i++) {
				colorNameBytes[i] = attributesBytes[start + i];
			}

			return string(colorNameBytes);

		} catch {

			// If the call to getColorData fails, color not minted. return the hex color.
			return colorhex;

		}

	}

	/**
	 * @dev In order to ensure that each 8x8 grid (and the animation) is
	 *      using unique hex color codes for each NFT, we'll use a simple
	 *      hashing function to convert the original 6 hex color code into
	 *      a different 6 hex color code.
	 */
	function _hashColorCode(uint256 originalColor, uint256 tokenId, uint256 hexStartIdx) internal pure returns (string memory) {

		uint256 hash = originalColor + tokenId + hexStartIdx;

		hash = ((hash >> 16) ^ hash) * 0x45d9f3b;
		hash = ((hash >> 16) ^ hash) * 0x45d9f3b;
		hash = (hash >> 16) ^ hash;

		// Modulo 2^24, so the result is exactly 6 hex chars in length
		hash = hash % 16777216;

		// Build the final 6 hex chars for the color code
		bytes memory result = new bytes(6);

		for (uint256 i = 0; i < 6; i++) {
			result[i] = HEX_SYMBOLS[(hash >> (4*i)) & 0xf];
		}

		return string(result);

	}

	/**
	 * @dev Checks if the sender is in the allowlist for Songbirdz holders.
	 */
	function _verifyAllowListProof(bytes32[] calldata proof) internal view returns (bool) {
		return MerkleProof.verify(
			proof,
			merkleTreeRoot,
			keccak256(abi.encodePacked(msg.sender)))
		;
	}

}
