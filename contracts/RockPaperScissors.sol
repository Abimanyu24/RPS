pragma solidity >=0.4.4 <0.9.0;

import "./IsStoppable.sol"; //inherit the Base contract

contract RockPaperScissors is Stoppable {

    enum Hand {NONE, Rock, Scissors, Paper}

    uint constant PLAYDEADLINE = 86400/15; //24 hours
    uint constant REVEALDEADLINE = 86400/15; //24 hours
    uint public globalPlayDeadline;
    uint public globalRevealDeadline;

    struct Game {
        uint p2PlayDeadline;
        uint p1RevealDeadline;
        
        address p1Address;
        bytes32 p1SecretHand;
        uint p1BetAmount;

        address p2Address;
        Hand p2Hand;
        uint p2BetAmount;
    }
    mapping (bytes32 => Game) games;

    event LogRockPaperScissorsNew (address _sender); 
    event LogRockPaperScissorsrpsGameStart (address _sender, bytes32 _hashGameID, bytes32 _secretHand);
    event LogRockPaperScissorsrpsGameEnd (address _sender, bytes32 _hashGameID, uint _p1Hand, uint _nonce);
    event LogRockPaperScissorsRefunExpiredGame (address _sender, bytes32 _hashGameID);
    event LogRockPaperScissorsrpsGameCancel (address _sender, bytes32 _hashGameID);
    event LogRockPaperScissorsrpsRefundGameBet (address _sender, bytes32 _hashGameID);
    event LogRockPaperScissorshandPlayerTwo (address _sender, bytes32 _hashGameID, uint _hand);

    constructor(uint _playDeadline, uint _revealDeadline) public
    {
        if (_playDeadline == 0) {
            globalPlayDeadline = PLAYDEADLINE;
        } else {
            globalPlayDeadline = _playDeadline;
        }
        if (_revealDeadline == 0) {
            globalRevealDeadline = REVEALDEADLINE;
        } else {
            globalRevealDeadline = _revealDeadline;
        }
        emit LogRockPaperScissorsNew(msg.sender);
    }

    //Generating new id for every player
    function generateNewGameId(address _player2) onlyIfRunning view public returns (bytes32 _hashGameID)
    {
        return keccak256(abi.encodePacked(msg.sender, _player2));
    }

    //get new secret hand
    function getNewHandSecret(bytes32 _hashGameID, uint _hand, uint _nonce) onlyIfRunning view public returns (bytes32 _secretHand)
    {
        return keccak256(abi.encodePacked(msg.sender, _hashGameID, _hand, _nonce));
    }

    // player 1 will start the game
    function rpsGameStart(bytes32 _hashGameID, bytes32 _secretHand) onlyIfRunning payable public returns (bool _success)
    {
        require (_hashGameID != 0, 'Error: game id shouldnot be zero');
        require (_secretHand != 0, 'Error: hand secret should not be zero');
        require (games[_hashGameID].p1SecretHand == 0); //require new game
        games[_hashGameID].p2PlayDeadline = globalPlayDeadline + now;
        Game storage game = games[_hashGameID]; //get a pointer to the game in storage
        game.p1RevealDeadline = globalRevealDeadline + now;
        game.p1Address = msg.sender;
        game.p1SecretHand = _secretHand;
        game.p1BetAmount = msg.value;
        emit LogRockPaperScissorsrpsGameStart (msg.sender, _hashGameID, _secretHand);
        return true;
    }

    // player two executes the function
    function handPlayerTwo(bytes32 _hashGameID, uint _hand) onlyIfRunning payable public returns (bool _success)
    {
        require (_hashGameID != 0, 'Error: Game id should not be 0');
        require (_hand != 0, 'Error: hand should not be 0');

        Game storage game = games[_hashGameID];
        require (game.p1Address != msg.sender);
        require (game.p1SecretHand != 0, 'Error: require existing game');
        require (game.p2Hand == Hand.NONE, 'Error: player2 should play only once');

        if (now > game.p2PlayDeadline) {
            rpsRefundGameBet (_hashGameID);
            return false;
        }

        game.p2Address = msg.sender;
        game.p2Hand = Hand(_hand);
        game.p2BetAmount = msg.value;

        emit LogRockPaperScissorshandPlayerTwo (msg.sender, _hashGameID, _hand);
        return true;
    }

    // function to end RPS game
    function rpsGameEnd(bytes32 _hashGameID, uint _p1Hand, uint _nonce) onlyIfRunning public returns (bool _success)
    {
        require (_hashGameID != 0, 'Error: Game hash is 0');
        require (_p1Hand != 0, 'Error: Game hand is 0');
        require (games[_hashGameID].p1Address != address(0x0), 'Error: Game address is 0');
        Game storage game = games[_hashGameID];
        require (game.p1SecretHand == getNewHandSecret(_hashGameID, _p1Hand, _nonce), 'Error: Game relevant and secret hand is different');

        if (now > game.p1RevealDeadline)
        {
            rpsRefundGameBet (_hashGameID);
            return false;
        }
        
        rpsRefundGameBet (_hashGameID);
        emit LogRockPaperScissorsrpsGameEnd (msg.sender, _hashGameID, _p1Hand, _nonce);
        return true;
    }

    // game gets tied refund the bet amount
    function rpsRefundGameBet(bytes32 _hashGameID) onlyIfRunning private returns (bool _success)
    {
        Game storage game = games[_hashGameID];
        address player1 = game.p1Address;
        address player2 = game.p2Address;
        delete games[_hashGameID]; //optimistic accounting
        emit LogRockPaperScissorsrpsRefundGameBet (msg.sender, _hashGameID);
        return true;
    }


    // Owner can cancel the game at any time
    function rpsGameCancel(bytes32 _hashGameID) onlyOwner public returns (bool _success)
    {
        require (_hashGameID != 0, 'Error: Game hash is 0');
        rpsRefundGameBet (_hashGameID);
        emit LogRockPaperScissorsrpsGameCancel (msg.sender, _hashGameID);
        return true;
    }

    function getInfoGame (bytes32 _hashGameID) view public returns(uint _globalPlayDeadline, 
            uint _globalRevealDeadline, 
            uint _p2PlayDeadline,
            uint _p1RevealDeadline, 
            address _p1Address, 
            bytes32 _p1SecretHand, 
            uint _p1BetAmount, 
            address _p2Address, 
            Hand _p2Hand, 
            uint _p2BetAmount)
    {
        Game storage game = games[_hashGameID];
        return (
            globalPlayDeadline,
            globalRevealDeadline,
            game.p2PlayDeadline,
            game.p1RevealDeadline,
            game.p1Address,
            game.p1SecretHand,
            game.p1BetAmount,
            game.p2Address,
            game.p2Hand,
            game.p2BetAmount
        );
    }
}
