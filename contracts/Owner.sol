pragma solidity >=0.4.4 <0.9.0;

contract Owned {
    address private owner;
    address private newOwner;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    event LogOwnedNew (address _sender);
    event LogOwnedChangeOwner (address _sender, address _newOwner);
    event LogOwnedConfirmChangeOwner (address _sender, address _newOwner);

    constructor() public
    {
        owner = msg.sender;
        emit LogOwnedNew(msg.sender);
    }

    function changeOwner(address _newOwner) onlyOwner public returns(bool _success)
    {
        require(_newOwner != address(0x0));
        newOwner = _newOwner;
        emit LogOwnedChangeOwner(msg.sender, _newOwner);
        return true;
    }

    function confirmChangeOwner() public returns(bool _success)
    {
        require(msg.sender == newOwner, 'Error: the sender address is not correct');
        owner = newOwner;
        delete newOwner;
        emit LogOwnedConfirmChangeOwner(msg.sender, newOwner);
        return true;
    }

    function getInfoOwner() view public returns (address _owner)
    {
        return owner;
    }

    function getInfoNewOwner() view public returns (address _newOwner)
    {
        return newOwner;
    }   
}