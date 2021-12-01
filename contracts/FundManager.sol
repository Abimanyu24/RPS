pragma solidity >=0.4.4 <0.9.0;
import "./IsStoppable.sol";

contract FundsManager is Stoppable {
    uint256 private contractFunds;
    uint256 private contractCommissions;

    struct Deposit {
        address depositor;
        uint256 amount;
    }
    mapping (bytes32 => Deposit) private deposits;
    mapping (address => uint256) private depositors;
    mapping (bytes32 => uint256) private commissions;

    event LogFundsManagerNew (address _sender);
    event LogFundsManagerfundsDepositnfo (address _sender, uint256 value);
    event LogFundsManagerfundTransfer (address _sender, address _origin, bytes32 _password);
    event LogFundsManagercomissionCharge (address _sender, bytes32 _hashTicket, uint256 _commissionAmount);
    event LogFundsManagercomissionRefundInfo (address _sender, bytes32 _hashTicket);

    modifier onlyDepositors() { 
        require(depositors[msg.sender] > 0); 
        _; 
    }

    constructor() public 
    {
        emit LogFundsManagerNew (msg.sender);
    }

    function fundsDepositnfo(bytes32 _hashTicket) onlyIfRunning internal returns (bool _success)
    {
        require (msg.value > 0, 'Error: Caller balance shold be sufficient');
        require (_hashTicket != 0, 'Error: Ticket should be zero');
        deposits[_hashTicket].depositor = msg.sender;
        deposits[_hashTicket].amount += msg.value;
        depositors[msg.sender] += 1; // This counter allows multiple deposits by the same sender with different hash tickets
        contractFunds += msg.value; // Soft accounting of the deposit
        emit LogFundsManagerfundsDepositnfo (msg.sender, msg.value);
        return true;
    }

    function newtransferTicketHashInfo(address _beneficiary, bytes32 _password) view public returns (bytes32 _transferTicketHashInfo)
    {
        return transferTicketHashInfo(msg.sender, _beneficiary, _password);
    }

    function transferTicketHashInfo(address _origin, address _beneficiary, bytes32 _password) view private returns (bytes32 _transferTicketHashInfo)
    {
        require (_origin != address(0x0), 'Error: address shouldnot be zero');
        require (_beneficiary != address(0x0), 'Error: Beneficary shouldnot be zero');
        require (_password != 0, 'Error: Password should not equals to zero');
        return keccak256(abi.encodePacked(msg.sender, _beneficiary, _password));
    }

    function fundTransfer(address _origin, bytes32 _password) onlyIfRunning internal returns (bool _success)
    {
        bytes32 hashTicketT = transferTicketHashInfo(_origin, msg.sender, _password);
        uint256 transferAmount = deposits[hashTicketT].amount; 
        require (transferAmount > 0);
        delete deposits[hashTicketT];
        msg.sender.transfer(transferAmount);
        emit LogFundsManagerfundTransfer (msg.sender, _origin, _password);
        return true;
    }

    function comissionCharge(bytes32 _hashTicket, uint256 _commissionAmount) internal returns (bool _success)
    {
        require (_hashTicket != 0, 'Error: ticket has equals to zero');
        require (commissions[_hashTicket] == 0, 'Error: More than one commission per ticket');
        uint256 originalAmount = deposits[_hashTicket].amount;
        require (originalAmount > 0, 'Error: Amount should be greater then zero');
        require (originalAmount - _commissionAmount > 0, 'Error: commission balance is negative');
        contractCommissions += _commissionAmount;
        contractFunds -= _commissionAmount;
        commissions[_hashTicket] = _commissionAmount;
        deposits[_hashTicket].amount = originalAmount - _commissionAmount;
        emit LogFundsManagercomissionCharge (msg.sender, _hashTicket, _commissionAmount);
        return true;
    }

    function comissionRefundInfo(bytes32 _hashTicket) internal returns (bool _success)
    {
        require (commissions[_hashTicket] > 0);
        uint256 refundAmount = commissions[_hashTicket];
        delete commissions[_hashTicket];
        contractCommissions -= refundAmount; // account the refund
        contractFunds += refundAmount; // add the commission to funds
        uint256 originalAmount = deposits[_hashTicket].amount;
        deposits[_hashTicket].amount = originalAmount + refundAmount;
        emit LogFundsManagercomissionRefundInfo (msg.sender, _hashTicket);
        return true;
    }

    function contractFundInfo() onlyOwner view public returns (uint256 _contractFunds)
    {
        return contractFunds;
    }

    function contractComissionInfo() onlyOwner view public returns (uint256 _contractCommissions)
    {
        return contractCommissions;
    }

    function depositInfo(bytes32 _hashTicket) view public returns (address _depositor, uint256 _amount)
    {
        require (_hashTicket != 0, 'Error: ticket hash equals zero');
        return (deposits[_hashTicket].depositor, deposits[_hashTicket].amount);
    }

    function comissionInformation(bytes32 _hashTicket) view public returns (uint256 _commissionAmount)
    {
        require (_hashTicket != 0, 'Error: ticket hash equals zero');
        return (commissions[_hashTicket]);
    }

    function depositor(address _depositor) view public returns (bool _isIndeed)
    {
        require (_depositor != address(0x0), 'Error: depositor equaks to zero');
        if (depositors[_depositor] > 0) {
            return true;
        } else {
            return false;
        }
    }
}