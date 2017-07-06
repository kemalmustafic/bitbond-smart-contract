pragma solidity ^0.4.11;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

 contract BettingContract is usingOraclize {
   address public organizer;
   address[] betsAddresses; 
   uint[] guesses;
   uint[] guessesDifferences;
   uint private betAmount = 2;

  string currentTemperature;

  event PlacedBet(address _from, uint _guess);
  event RemovedBet(address _from);
  event Payout();

  function BettingContract() {
    organizer = msg.sender;
    betAmount = 2;

    update();
  }

  function placeBet(uint guess) payable {
    if(msg.value != betAmount) { return; }

    betsAddresses.push(msg.sender);
    guesses.push(guess);

    PlacedBet(msg.sender, guess);
  } 

  function removeBet() payable {
    for(uint i = 0; i < betsAddresses.length; i++) {
      if(msg.sender == betsAddresses[i]) {
        betsAddresses[i] = betsAddresses[betsAddresses.length - 1];
        guesses[i] = guesses[guesses.length - 1];

        betsAddresses.length--;
        guesses.length--;
      }
    }
  }

  function getGuesses() public returns (uint[] allGuesses) {
    return guesses; 
  }

  function getAddresses() constant public returns (address[] allAddresses) {
    return betsAddresses;
  }

  function refund() payable {
    if(msg.sender != organizer) { return; }

    for(uint i = 0; i < betsAddresses.length; i++) {
      betsAddresses[i].transfer(betAmount);
    }

    delete betsAddresses;
    delete guesses;
  }

  function __callback(bytes32 myid, string result) {
    if (msg.sender != oraclize_cbAddress()) throw;
      
    currentTemperature = result;
  }
    
  function update() payable {
    oraclize_query("WolframAlpha", "temperature in Berlin");
  }

  function getCurrentTemperature() constant returns (string temperature) {
    return currentTemperature;
  }

  function payout() payable {
    for(uint i = 0; i < guesses.length; i++) {
      uint currentDifference = stringToUint(currentTemperature) - guesses[i];
      if (currentDifference < 0) {
          currentDifference =  -currentDifference;
      }
      
      guessesDifferences.push(currentDifference);
    }
      
    uint bestGuessIndex = 0;

    for(uint j = 1; j < guessesDifferences.length; j++) {
      if(guessesDifferences[j] < guessesDifferences[bestGuessIndex]) {
        bestGuessIndex = j;
      }
    }

    betsAddresses[bestGuessIndex].transfer(betAmount * guesses.length);   

    Payout();    
  }

  function stringToUint(string s) returns (uint result) {
    bytes memory b = bytes(s);
    uint i;

    result = 0;

    for (i = 0; i < b.length; i++) {
      uint c = uint(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
  }

  function destroy() {
    if(msg.sender == organizer) {
      suicide(organizer);
    }
  }
 }