pragma solidity 0.6.8;
/*
    Fast Rent Blockchain Utility Token
    This token is used to pay rents and be able the evaluate stays
*/
contract FRBToken {
    string public name;
    string public symbol;
    address payable FRBTeam;
    mapping(address => uint) balances;
    
    constructor() public {
        name = 'Fast Rent Blockchain';
        symbol = 'FRB';
        FRBTeam = msg.sender;
    }

    function buyTokens() public payable {
        uint nWeis = msg.value;
        FRBTeam.transfer(nWeis);
        balances[msg.sender] += nWeis / 1000;
    }

    function transferTokens(address _source, address _target, uint _numTokens) public {
        require(_source == tx.origin);
        require(balances[_source] > _numTokens);
        balances[_source] -= _numTokens;
        balances[_target] += _numTokens;
    }

    function getBalance(address _wallet) public view returns (uint) {
        return balances[_wallet];
    }
}