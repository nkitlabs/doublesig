// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract DoubleSig {
    struct PendingTransfer {
        address address_to;
        uint amount;
        bool[] owner_approved;
        uint total_approved;
        bool is_exist;
        bool is_paid;
    }
    
    // array vs mapping 
    mapping (uint => PendingTransfer) public pending_transfer;
    
    uint public running_no;
    mapping (address => uint) public owner_id;
    address[] public owner_list;
    
    
    constructor (address owner1, address owner2) public {
        owner_list = [ owner1, owner2 ];
        running_no = 0;
        
        for (uint i = 0; i < owner_list.length; i++ ) {
        owner_id[owner_list[i]] = i+1;
        }  

    }
    
    // Return the first owner, set in constructor.
    function owner1() public view returns (address) {
        return owner_list[0];
    }
    
    // Return the second owner, set in constructor.
    function owner2() public view returns (address){
        return owner_list[1];
    }
    
    // Anyone can deposit ETH to this smart contract via this function
    function deposit() external payable{}

    // owner1 or owner2 can initiate a transfer of ETH. Return an incremental unique id per initiate.
    function initiate(address to, uint amount) external returns (uint id){
        require(owner_id[msg.sender] >= 1, "caller must be an owner of the system.");
        
        uint _owner_id = owner_id[msg.sender] - 1;
        PendingTransfer memory transfer_txn;
        transfer_txn.address_to = to;
        transfer_txn.amount = amount;
        transfer_txn.owner_approved = new bool[](owner_list.length);
        transfer_txn.owner_approved[_owner_id] = true;
        transfer_txn.total_approved = 1;
        transfer_txn.is_exist = true;
        transfer_txn.is_paid = false;
        
        id = running_no;
        running_no += 1;
        
        pending_transfer[id] = transfer_txn;
        return id;
    }
    
    // another owner can approve the unique id of an initiation. The transfer will happen here. 
    // Revert on invalid id or if caller is not the other owner.
    function approve(uint initiate_id) external {
        require(owner_id[msg.sender] >= 1, "caller must be an owner of the system.");
        require(pending_transfer[initiate_id].is_exist, "invalid id");
        require(!pending_transfer[initiate_id].is_paid, "This request has been paid");
        
        uint _owner_id = owner_id[msg.sender] - 1;
        uint amount = pending_transfer[initiate_id].amount;
        address payable address_to = payable(pending_transfer[initiate_id].address_to);
        require(!pending_transfer[initiate_id].owner_approved[_owner_id], "this owner already approved it");
        
        pending_transfer[initiate_id].owner_approved[_owner_id] = true;
        pending_transfer[initiate_id].total_approved += 1;
        
        require(pending_transfer[initiate_id].total_approved == owner_list.length, 
        "owner approved successfully; wait for others to approve this transaction");
        
        address_to.transfer(amount);
        pending_transfer[initiate_id].is_paid = true;
    }
}