import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;

interface ISeed is IERC721 {
  function regist(uint256 tokenId_, string[] memory names_) external returns (bool) ;
  function getSeed(uint256 tokenId) external view returns (uint256);
  function getValueByProject(uint256 tokenId_, string memory name_, address project_) external view returns (uint256[] memory);
  function getRandomNumber(uint256 tokenId, uint256 index) external view returns (uint256);
  function getRandomNumberInRange(uint256 tokenId_, uint256 start_, uint256 end_) external view returns (uint256[] memory);

}

contract Seed is ISeed, ERC721{

  using SafeMath for uint256;

  uint256 _limitTid = 10000;
  uint256 _lastTid = 0;
  uint256 _mintPrice = 0;


  // {TokenId: Seed}
  mapping(uint256 => uint256) private _seeds;
  // {TokenId: DataSlots}
  mapping(uint256 => string[]) private _slots;

  struct Record {
    address addr;
    uint256 slotStart;
    uint256 slotEnd;
    bool display;
  }
  // {TokenId: Records{contract, start, end}}
  mapping(uint256 => Record[]) private _records;


  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) public {
  }

  function regist(uint256 tokenId_, string[] memory names_) external override returns (bool) {
    require(ownerOf(tokenId_) == tx.origin, "tx sender not own this Seed");

    uint start_slot = _slots[tokenId_].length;

    for (uint i=0; i < names_.length; i++) {
      _slots[tokenId_].push(names_[i]);
    }

    uint end_slot = start_slot + names_.length;

    Record memory rec = Record(msg.sender, start_slot, end_slot, false);
    _records[tokenId_].push(rec);
    return true;
  }

  function getRecord(uint256 tokenId_, address project_) external view returns (Record memory) {
     for (uint i=0; i<_records[tokenId_].length; i++) {
       if (_records[tokenId_][i].addr == project_) {
	 return _records[tokenId_][i];
       }
     }
  }

  function getValueByProject(uint256 tokenId_, string memory name_, address project_) external override view returns (uint256[] memory) {

    Record memory rec = this.getRecord(tokenId_, project_);
    uint256 start_ = rec.slotStart;
    uint256 end_ = rec.slotEnd;
    return this.getRandomNumberInRange(tokenId_, start_, end_);
  }

  function getSeed(uint256 tokenId) external override view returns (uint256) {
    require(tokenId <= _limitTid, "TokenId not exists");
    return _seeds[tokenId];
  }

  function getRandomNumber(uint256 tokenId, uint256 index) external override view returns (uint256) {
    uint256 ret = this.getSeed(tokenId);
    for (uint i=0; i < index; i++) {
      ret = uint256(keccak256(abi.encode(ret)));
    }
    return ret;
  }

  function getRandomNumberInRange(uint256 tokenId_, uint256 start_, uint256 end_) external override view returns (uint256[] memory) {
    uint256[] memory ret;
    uint j = 0;
    for (uint i=start_; i < end_; i++) {
      ret[j] = this.getRandomNumber(tokenId_, i);
      j++;
    }
    return ret;
  }

  function mint() public payable {
    require(msg.value >= _mintPrice, "Insufficient value");
    require(_lastTid <= _limitTid, "Sold out");

    _safeMint(msg.sender, _lastTid);

    _seeds[_lastTid] = genSeed();
    _lastTid++;
  }

  function genSeed() private returns (uint256) {
    // Gen seed, Consider that all random number has no value,
    // so just simply using sum of
    // addr , block_Timestamp and difficulty
    return uint256(
      keccak256(
	abi.encode(uint256(uint160(address(msg.sender))).add(block.timestamp).add(block.difficulty))
	)
      );
  }
}
