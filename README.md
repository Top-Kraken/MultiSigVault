# MultiSigVault Module

## Overview

The main purpose of MultiSigVault is to increase security by requring multiple accounts to agree on transactions before execution. Transactions can be executed only when confirmed by a predefined numbers of signers. It supports ERC-20 tokens for the transactions.

## How to Use
1. Deploy smart contract via `Bunzz`
2. Set `token` address by calling `connectToOtherContracts` function and deposit tokens to the vault.
3. Add SIGNER_ROLE to the signers accounts by calling `grantRole` function.

```
const SIGNER_ROLE = web3.utils.soliditySha3("SIGNER");
await multiSigVault.grantRole(SIGNER_ROLE, signer_account);
```

4. Using `setSignerLimit` function, set the required number of confirmations of every transactions.
5. By calling `addTransaction` function, add new transaction. Any signer account can add transactions.
6. Signer accounts can sign/reject the transaction by calling `signTransaction` and `rejectTransaction` functions.
7. After transaction has enough confirmations, signers can execute transaction by calling `executeTransaction` functions.

## Functions