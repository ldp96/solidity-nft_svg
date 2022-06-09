pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import "hardhat/console.sol";
import './HexStrings.sol';
import './ToColor.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() public ERC721("Loogies", "LOOG") {
    // RELEASE THE LOOGIES!
  }

  mapping (uint256 => bytes3) public color;
  mapping (uint256 => uint256) public chubbiness;
  mapping (uint256 => uint256) public happiness;

  uint256 mintDeadline = block.timestamp + 24 hours;

  function mintItem()
      public payable
      returns (uint256)
  {
      require(msg.value>=0.0010 ether, "not enough");
      require( block.timestamp < mintDeadline, "DONE MINTING");
      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id ));
      color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
      chubbiness[id] = 35+((55*uint256(uint8(predictableRandom[3])))/255);
      happiness[id] = 263-(uint256(uint8(predictableRandom[4]))%90);
      console.log(happiness[id]);

      return id;
  }

  function withdraw() public onlyOwner {
      require(address(this).balance>0, "got 0");

      payable(msg.sender).transfer(address(this).balance);
  }

  function getBalance() public view returns(uint){
    return address(this).balance;
  }
  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory humor;
      if (happiness[id]>=220 && happiness[id]<250)
        humor = "happy";
      else if (happiness[id]>=250)
        humor = "super happy";
      else if (happiness[id]<220 && happiness[id]>=200)
        humor = "unhappy";
      else
        humor = "really sad";
    
      string memory name = string(abi.encodePacked('Loogie #',id.toString()));
      string memory description = string(abi.encodePacked('This Loogie is the color #',color[id].toColor(),' with a chubbiness of ',uint2str(chubbiness[id]),' and it is ',humor,'!!!'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://burnyboys.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "color", "value": "#',
                              color[id].toColor(),
                              '"},{"trait_type": "chubbiness", "value": ',
                              uint2str(chubbiness[id]),
                              '},{"trait_type": "happiness", "value": ',
                              uint2str(happiness[id]),
                              '}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    uint256 happy;
    if (happiness[id]>220)
      happy = happiness[id] + 20;
    else
      happy = happiness[id] - 20;

      console.log ("happy: ", happy);
      console.log ("happiness: ", happiness[id].toString());
    string memory render = string(abi.encodePacked(
      '<g id="eye1">',
          '<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_1" cy="154.5" cx="181.5" stroke="#000" fill="#fff"/>',
          '<ellipse ry="3.5" rx="2.5" id="svg_3" cy="154.5" cx="173.5" stroke-width="3" stroke="#000" fill="#000000"/>',
        '</g>',
        '<g id="head">',
          '<ellipse fill="#',
          color[id].toColor(),
          '" stroke-width="3" cx="204.5" cy="211.80065" id="svg_5" rx="',
          chubbiness[id].toString(),
          '" ry="51.80065" stroke="#000"/>',
         // draw a path for the smile
          '<path d="M ',
          ((409 - (chubbiness[id])*2) / 2 ).toString(),' 220 C ', (((409 - (chubbiness[id])*2) / 2 )+20).toString(),' ',happiness[id].toString(), ',',(((409 - (chubbiness[id])*2) / 2 )+30).toString(),' ',happy.toString(),', 204.5 220" stroke="black" fill="transparent"/>',
        '</g>',
        '<g id="eye2">',
          '<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_2" cy="168.5" cx="209.5" stroke="#000" fill="#fff"/>',
          '<ellipse ry="3.5" rx="3" id="svg_4" cy="169.5" cx="208" stroke-width="3" fill="#000000" stroke="#000"/>',
        '</g>'
      ));

    return render;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}
