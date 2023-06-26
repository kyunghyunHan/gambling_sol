// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lottery {
    address public owner;
    address payable[] public players;

    constructor(){
         owner= msg.sender;
    }
     

    function getBalance()public view returns (uint256){
        return address(this).balance;
    }
    function enter()public payable{
        require(msg.value>=0.01 ether,"msg.value should be greater then or equal to 0.01 ether");

        players.push(payable(msg.sender));
    }
}