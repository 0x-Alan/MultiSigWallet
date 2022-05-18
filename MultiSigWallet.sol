// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount)
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    // A modifier that checks if the sender is an owner.
    modifier OnlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    //A modifier that checks if the transaction exists.
    modifier txExists(uint txId) {
        require(_txId < transactions.length, "transaction does not exist");
        _;
    }

    //A modifier that checks if the transaction has already been approved.
    modifier notApproved(uint txId) {
        require(!approved[_txId][msg.sender], "transaction already approved");
        _;
    }

    //Checking if the transaction has already been executed.
    modifier notExectued(uint txId) {
        require(!transactions[_txId].executed, "transaction already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required number of owners");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner !=-= address(0), "invalid owner");
            require(!isOwner[owner], "owner already registered");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    // This is a fallback function that is called when a contract receives Ether.
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    //This function is used to submit a transaction to the wallet.
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    //Approving the transaction.
    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExectued(_txId) {
        approve[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    //A private function that returns the number of approvals for a given transaction.
    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count+= 1;
            }
        }
    }

    function executed(uint _txId) external txExists(_txId) notExectued(_txId) {
        require(_getApprovalCount(_txId) >= required, "insufficient approvals");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool succes, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "transaction failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExectued(_txId) {
        require(approved[_txId][msg.sender], "transaction not approved");])
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

}