// SPDX-License-Identifier: MITX
pragma solidity 0.8.7;

contract Multisig {
    address[] public approvers;
    uint public quorum;
    uint nextId;

    struct Transfer {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    mapping(uint => Transfer) public transfers;
    
    mapping(address => mapping(uint => bool)) public approvals;

    constructor(address[] memory _approvers, uint _quorum) payable {
        approvers = _approvers;
        quorum = _quorum;
    }

    function createTransfer(uint amount, address payable to) onlyApprover() external {
        transfers[nextId] = Transfer(
            nextId,
            amount,
            to,
            0,
            false
        );
        nextId++;
    }

    function sendTransfer(uint id) onlyApprover() external returns (string memory message){
        require(transfers[id].sent == false, "transfer has already been sent");
        if(approvals[msg.sender][id] == false) {
            approvals[msg.sender][id] = true;
            transfers[id].approvals++;
        }
        
        if(transfers[id].approvals >= quorum) {
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            // to.transfer(amount);
            (bool sent, ) = to.call{value: amount}("");
            require(sent, "Money not sent to the user!");
            return "Funds moved.";
        } else {
            return "Pending signatures from other users yet";
        }
    }

    modifier onlyApprover() {
        bool allowed = false;
        for(uint i; i < approvers.length; i++) {
            if(approvers[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed, "only approver allowed");
        _;
    }
}
