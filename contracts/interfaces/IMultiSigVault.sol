// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of Bunzz MultiSigVault
 */

interface IMultiSigVault {
    event TransactionCreated(
        address indexed account,
        address indexed to,
        uint256 amount,
        uint256 unlockTime,
        uint256 transactionId
    );

    event TransactionSigned(address indexed account, uint256 transactionId);

    event TransactionRejected(address indexed account, uint256 transactionId);

    event TransactionCompleted(
        address indexed account,
        address indexed to,
        uint256 amount,
        uint256 unlockTime,
        uint256 transactionId
    );

    function balance() external view returns (uint256);

    function setSignerLimit(uint256 _signerLimit) external;

    function addTransaction(
        address payable _to,
        uint256 _amount,
        uint256 _unlockTime
    ) external returns (uint256);

    function signTransaction(uint256 _transactionId) external;

    function rejectTransaction(uint256 _transactionId) external;

    function executeTransaction(uint256 _transactionId) external;

    function emergencyWithdraw() external;
}
