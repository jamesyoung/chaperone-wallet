pragma solidity 0.4.18;

import {SafeMath} from "./SafeMath.sol";

contract Chaperone {
  using SafeMath for uint;

  uint public waitingPeriodInSeconds;
  address public chaperone;
  
  mapping (address => uint) pending;
  mapping (address => bool) owners;

  event SubmitOwnerEvent(address indexed newOwner, uint indexed pendingComplete);
  event RejectOwnerEvent(address indexed rejectedOwner, uint indexed rejectedTimestamp);
  event ApproveOwnerEvent(address indexed approvedOwner, uint indexed approvedTimestamp);
  event ExecuteEvent(address indexed owner, address indexed destination, uint indexed value, bytes data);

  modifier isOwner {
      assert(owners[msg.sender] == true);
      _;
  }

  modifier isChaperone {
      assert(chaperone == msg.sender);
      _;
  }

  function Chaperone(address _owner, address _chaperone, uint _waitingPeriodInSeconds) public {
    require(_owner != address(0));
    require(_chaperone != address(0));
    require(_waitingPeriodInSeconds != 0);

    owners[_owner] = true;
    chaperone = _chaperone;
    waitingPeriodInSeconds = _waitingPeriodInSeconds;
  }

  function submitOwner(address _pending) isChaperone public {
      require(owners[_pending] == false);
      require(pending[_pending] == 0);

      uint pendingComplete = waitingPeriodInSeconds.add(block.timestamp);
      pending[_pending] = pendingComplete;
      
      SubmitOwnerEvent(_pending, pendingComplete);
  }

  function rejectOwner(address _pending) isOwner public {      
      pending[_pending] = 0;
      
      RejectOwnerEvent(_pending, block.timestamp);
  }

  function approveOwner(address _pending) isChaperone public {
      require(pending[_pending] != 0);
      require(pending[_pending] < waitingPeriodInSeconds.add(block.timestamp));
      
      owners[_pending] = true;
      
      ApproveOwnerEvent(_pending, block.timestamp);
  }
  
  function execute(address destination, uint value, bytes data) isOwner public {
    require(destination.call.value(value)(data));

    ExecuteEvent(msg.sender, destination, value, data);
  }

  function () public payable {}
}