# Rock Paper Scissors

Player_1 and Player_2 can play the classic rock paper scissors game.
- to enrol, each player needs to deposit the right Ether amount.
- to play, each player submits their unique move.
- the contract decides and rewards the winner with all Ether.

Rules:
       Winner    Losers
     - Paper >   Rock
     - Scissor > Paper
     - Rock >    Scissor

Workflow:
- Player_1 requests a newGame with newPlayer(Player_2).
- Player_1 plays their SecretHand. Sets expiration times to play and reveal
- Player_2 plays in the clear (before expiration time)
- Player_1 ends the game by revealing their SecretHand (before reveal expiration time)
- Contract rewards the winner and refunds any leftover bet amount to the players

