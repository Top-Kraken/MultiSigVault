import { ethers } from "hardhat";
import { expect } from "chai";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ContractFactory, Contract } from "ethers";
import "@nomiclabs/hardhat-ethers";
import web3 from "web3";

const SIGNER_ROLE = web3.utils.soliditySha3("SIGNER")
const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000'

describe("Test MultiSigVault", function () {
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;
    let multiSigVaultFactory: ContractFactory;
    let multiSigVault: Contract;
    let mockTokenFactory: ContractFactory;
    let mockToken: Contract;

    before(async function () {
        // Getting the users provided by ethers
        [owner, addr1, addr2] = await ethers.getSigners();

        // Getting the MultiSigVault contract code (abi, bytecode, name)
        multiSigVaultFactory = await ethers.getContractFactory("MultiSigVault");

        // Deploying the instance
        multiSigVault = await multiSigVaultFactory.deploy();
        await multiSigVault.deployed();

        // Getting the ERC20Mock contract code (abi, bytecode, name)
        mockTokenFactory = await ethers.getContractFactory("ERC20Mock");

        // Deploying the instance
        mockToken = await mockTokenFactory.deploy("MockToken", "MK");
        await mockToken.deployed();
    })

    it("check deployment", async function () {
    })

    describe("before token set", function () {
        it("revert get balance if token is not set", async function () {
            await expect(multiSigVault.balance()).to.be.revertedWith("token isn't set")
        })

        it("revert withdraw if token is not set", async function () {
            await expect(multiSigVault.emergencyWithdraw()).to.be.revertedWith("token isn't set")
        })
    })

    describe("check role", function () {
        before(async function () {
            await multiSigVault.grantRole(SIGNER_ROLE, addr1.address)
        })

        it('deployer has default admin role', async function () {
            expect(await multiSigVault.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.equal(true)
        })

        it('non-admin cannot grant role to other accounts', async function () {
            await expect(
                multiSigVault.connect(addr2).grantRole(SIGNER_ROLE, addr1.address)
            ).to.be.revertedWith(
                `AccessControl: account ${addr2.address.toLowerCase()} is missing role ${DEFAULT_ADMIN_ROLE}`
            );
        })
    })
})