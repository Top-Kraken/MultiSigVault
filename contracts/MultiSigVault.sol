// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IMultiSigVault.sol";
import "./interfaces/IBunzz.sol";

contract MultiSigVault is
    Ownable,
    AccessControlEnumerable,
    ReentrancyGuard,
    IMultiSigVault,
    IBunzz
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant SIGNER = keccak256("SIGNER");
    uint256 public signerLimit;
    IERC20 public token;

    struct Transaction {
        address payable to;
        uint256 amount;
        uint256 unlockTime;
        uint256 signatureCount;
        mapping(address => bool) signatures;
        bool executed;
    }

    Counters.Counter private _txIds;
    mapping(uint256 => Transaction) public transactions;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function connectToOtherContracts(address[] calldata contracts)
        public
        override
        onlyOwner
    {
        require(contracts.length > 0, "invalid contracts length");
        require(contracts[0] != address(0), "invalid contract address");

        if (token != IERC20(address(0))) {
            require(
                token.balanceOf(address(this)) == 0,
                "remain origin tokens."
            );
        }
        token = IERC20(contracts[0]);
    }

    function setSignerLimit(uint256 _signerLimit) public onlyOwner {
        require(_signerLimit > 0, "signer limit is 0");
        require(
            _signerLimit <= getRoleMemberCount(SIGNER),
            "signer limit is greater than member count"
        );
        signerLimit = _signerLimit;
    }

    function addTransaction(
        address payable _to,
        uint256 _amount,
        uint256 _unlockTime
    ) public nonReentrant onlyRole(SIGNER) returns (uint256) {
        require(_to != address(0), "invalid to address");
        require(_amount > 0, "amount is 0");
        require(
            _unlockTime < 10000000000,
            "Enter an unix timestamp in seconds, not miliseconds"
        );

        uint256 current = _txIds.current();
        transactions[current].to = _to;
        transactions[current].amount = _amount;
        transactions[current].unlockTime = _unlockTime;

        _txIds.increment();
        emit TransactionCreated(msg.sender, _to, _amount, _unlockTime, current);

        return current;
    }

    function signTransaction(uint256 _transactionId)
        public
        nonReentrant
        onlyRole(SIGNER)
    {
        Transaction storage transaction = transactions[_transactionId];

        require(transaction.to != address(0), "invalid transaction");
        require(transaction.signatures[msg.sender] != true, "already signed");

        transaction.signatures[msg.sender] = true;
        transaction.signatureCount = transaction.signatureCount.add(1);

        emit TransactionSigned(msg.sender, _transactionId);
    }

    function rejectTransaction(uint256 _transactionId)
        public
        nonReentrant
        onlyRole(SIGNER)
    {
        Transaction storage transaction = transactions[_transactionId];

        require(transaction.to != address(0), "invalid transaction");
        require(transaction.signatures[msg.sender] != false, "already signed");

        transaction.signatures[msg.sender] = false;
        transaction.signatureCount = transaction.signatureCount.add(1);

        emit TransactionRejected(msg.sender, _transactionId);
    }

    function executeTransaction(uint256 _transactionId)
        public
        nonReentrant
        onlyRole(SIGNER)
    {
        Transaction storage transaction = transactions[_transactionId];

        require(token != IERC20(address(0)), "invalid token");
        if (transaction.unlockTime > 0) {
            require(
                block.timestamp >= transaction.unlockTime,
                "transaction is locked"
            );
        }
        require(!transaction.executed, "transaction already executed");
        require(
            token.balanceOf(address(this)) >= transaction.amount,
            "you don't have enough funds"
        );
        require(
            transaction.signatureCount >= signerLimit,
            "you don't have enough signatures"
        );

        SafeERC20.safeTransfer(token, transaction.to, transaction.amount);

        transactions[_transactionId].executed = true;

        emit TransactionCompleted(
            msg.sender,
            transaction.to,
            transaction.amount,
            transaction.unlockTime,
            _transactionId
        );
    }

    function balance() public view returns (uint256) {
        require(token != IERC20(address(0)), "invalid token");
        return token.balanceOf(address(this));
    }

    function emergencyWithdraw() public onlyOwner {
        require(token != IERC20(address(0)), "invalid token");
        uint256 _amount = token.balanceOf(address(this));
        require(_amount > 0, "balance is 0");
        SafeERC20.safeTransfer(token, owner(), _amount);
    }
}
