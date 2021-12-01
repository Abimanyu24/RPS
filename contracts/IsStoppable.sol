pragma solidity >=0.4.4 <0.9.0;
import "./Owner.sol";

contract Stoppable is Owned {
    bool private stop;
    event LogStoppableNew (address _sender);
    event LogStoppableresumeStoppedContract (address _sender);
    event LogStoppablestopRunningContract (address _sender);
    
    modifier onlyIfRunning () { 
        require (!stop);
        _;
    }

    constructor() public {
        emit LogStoppableNew (msg.sender);
    }

    function stopRunningContract() onlyOwner public returns (bool _success)
    {
        stop = true;
        emit LogStoppablestopRunningContract (msg.sender);
        return true;
    }

    function resumeStoppedContract() onlyOwner public returns (bool _success)
    {
        stop = false;
        emit LogStoppableresumeStoppedContract (msg.sender);
        return true;
    }

    function isContractStopped() public view returns (bool _stop)
    {
        return stop;
    }
}