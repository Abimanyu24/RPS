pragma solidity >=0.4.4 <0.9.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public{
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgradeInfo(address new_address) public restricted {
    Migrations upgradeInformation = Migrations(new_address);
    upgradeInformation.setCompleted(last_completed_migration);
  }
}
