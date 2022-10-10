// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/// @notice The structure that contains meta information of the L2 transaction that was requested from L1
/// @dev The weird size of fields was selected specifically to minimize the structure storage size
/// @param canonicalTxHash Hashed L2 transaction data that is needed to process it
/// @param expirationBlock Expiration block number (ETH block) for this request (must be satisfied before)
/// @param layer2Tip Additional payment to the validator as an incentive to perform the operation
struct PriorityOperation {
    bytes32 canonicalTxHash;
    uint64 expirationBlock;
    uint192 layer2Tip;
}

/// @author Matter Labs
/// @dev The library provides the API to interact with the priority queue container
/// @dev Order of processing operations from queue - FIFO (Fist in - first out)
library PriorityQueue {
    using PriorityQueue for Queue;

    /// @notice Container that stores priority operations
    /// @param data The inner mapping that saves priority operation by its index
    /// @param head The pointer to the last added priority operation
    /// @param tail The pointer to the first unprocessed priority operation
    struct Queue {
        mapping(uint256 => PriorityOperation) data;
        uint256 head;
        uint256 tail;
    }

    /// @return Index of the oldest priority operation that wasn't processed yet
    /// @notice Returns zero if and only if no operations were processed from the queue
    function getFirstUnprocessedPriorityTx(Queue storage _queue) internal view returns (uint256) {
        return _queue.tail;
    }

    /// @return The total number of priority operations that were added to the priority queue, including all processed ones
    function getTotalPriorityTxs(Queue storage _queue) internal view returns (uint256) {
        return _queue.head;
    }

    /// @return The total number of unprocessed priority operations in a priority queue
    function getSize(Queue storage _queue) internal view returns (uint256) {
        return uint256(_queue.head - _queue.tail);
    }

    /// @return Whether the priority queue contains no operations
    function isEmpty(Queue storage _queue) internal view returns (bool) {
        return _queue.head == _queue.tail;
    }

    /// @notice Add the priority operation to the end of the priority queue
    function pushBack(Queue storage _queue, PriorityOperation memory _operation) internal {
        // Save value into the stack to avoid double reading from the storage
        uint256 head = _queue.head;

        _queue.data[head] = _operation;
        _queue.head = head + 1;
    }

    /// @return The first unprocessed priority operation from the queue
    function front(Queue storage _queue) internal view returns (PriorityOperation memory) {
        require(!_queue.isEmpty(), "D"); // priority queue is empty

        return _queue.data[_queue.tail];
    }

    /// @notice Remove the first unprocessed priority operation from the queue
    /// @return priorityOperation that was popped from the priority queue
    function popFront(Queue storage _queue) internal returns (PriorityOperation memory priorityOperation) {
        require(!_queue.isEmpty(), "s"); // priority queue is empty

        // Save value into the stack to avoid double reading from the storage
        uint256 tail = _queue.tail;

        priorityOperation = _queue.data[tail];
        delete _queue.data[tail];
        _queue.tail = tail + 1;
    }
}
