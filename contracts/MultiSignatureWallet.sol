pragma solidity ^0.4.15;

contract MultiSignatureWallet {
    
    event Submission(uint indexed transactionId);

    event Confirmation(address indexed sender, uint indexed transactionId);

    event Execution(uint indexed transactionId);

    event ExecutionFailure(uint indexed transactionId);

    // Array to store owner addresses
    address[] public owners;

    // Number of required confirmations
    uint public required;

    // Counter for transactionId
    uint public transactionCount;

    // Mapping to reference whether a given address is an owner
    mapping(address => bool) public isOwner;

    // Mapping to reference transactions based on transactionId
    mapping(uint => Transaction) public transactions;

    // Mapping to store which owners have confirmed which transaction
    mapping(uint => mapping(address => bool)) public confirmations;

    struct Transaction {
      bool executed;
      address destination;
      uint value;
      bytes data;
    }

    /// @dev Fallback function, which accepts ether when sent to contract
    function() public payable {}

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for(uint i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }


    modifier validRequirement(uint ownerCount, uint _required) {
        if(_required > ownerCount || _required == 0 || ownerCount == 0){
            revert();
        }
        _;
    }

    //  function MultiSignatureWallet(address[] _owners, uint _required) public {}

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data) public returns (uint transactionId) {
        // require caller of this function to be an owner
        require(isOwner[msg.sender]);

        // call helper functions
        transactionId = addTransaction(destination, value, data);
        isConfirmed(transactionId);

        // function header will automatically return transactionId

    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public {

        // require only wallet owners can call this function
        require(isOwner[msg.sender]);

        // require a transaction exists at the specified transactionId
        require(transactions[transactionId].destination != 0);

        // require msg.snder has not already confirmed this transaction
        require(confirmations[transactionId][msg.sender] == false);

        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);

    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {}

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public {

        require(transactions[transactionId].executed == false);

        if(isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if(txn.destination.call.value(txn.value)(txn.data)){
                emit Execution(transactionId);
            }
            else{
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

        /*
         * (Possible) Helper Functions
         */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) public constant returns (bool) {
        uint count = 0;
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[transactionId][owners[i]] == true){
                count += 1;
            }
            if(count == required){
                return true;
            }
        }
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data) internal returns (uint transactionId) {

        // set transactionId based on latest transactionCount
        transactionId = transactionCount;

        // add new Transaction to mapping
        transactions[transactionId] = Transaction({
            executed: false,
            destination: destination,
            value: value,
            data: data
        });
        transactionCount += 1;
        emit Submission(transactionId);
        
    }


}
