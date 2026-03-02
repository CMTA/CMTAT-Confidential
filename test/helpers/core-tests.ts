import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';
import {
  TOKEN_NAME,
  TOKEN_SYMBOL,
  CONTRACT_URI,
  DEFAULT_ADMIN_ROLE,
  MINTER_ROLE,
  encryptAmount,
  decryptBalance,
  mint,
} from './deploy';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';

/**
 * Shared core test suite for CMTATFHE and CMTATFHELite.
 *
 * Call this function inside a describe block that has a beforeEach setting:
 *   this.token, this.admin, this.minter, this.burner, this.pauser,
 *   this.enforcer, this.holder, this.recipient, this.accounts
 */
export function runCoreTests() {
  function getHandleFromReceipt(factory: any, receipt: any): string {
    for (const log of receipt.logs) {
      try {
        const parsed = factory.interface.parseLog(log);
        if (parsed?.name === 'HandleCreated') {
          return parsed.args.handle;
        }
      } catch {
        // ignore non-matching logs
      }
    }
    throw new Error('HandleCreated event not found');
  }

  beforeEach(async function () {
    this.factory = await ethers.deployContract('Euint64Factory');
  });
  // ─── constructor ─────────────────────────────────────────────────────────

  describe('constructor', function () {
    it('sets the name', async function () {
      expect(await this.token.name()).to.equal(TOKEN_NAME);
    });

    it('sets the symbol', async function () {
      expect(await this.token.symbol()).to.equal(TOKEN_SYMBOL);
    });

    it('sets the contractURI', async function () {
      expect(await this.token.contractURI()).to.equal(CONTRACT_URI);
    });

    it('sets decimals to 6', async function () {
      expect(await this.token.decimals()).to.equal(6);
    });

    it('grants DEFAULT_ADMIN_ROLE to admin', async function () {
      expect(await this.token.hasRole(DEFAULT_ADMIN_ROLE, this.admin.address)).to.be.true;
    });

    it('exposes the CMTAT FHE version', async function () {
      expect(await this.token.version()).to.equal('0.1.0');
    });
  });

  // ─── access control ──────────────────────────────────────────────────────

  describe('access control', function () {
    it('admin can grant roles', async function () {
      const newMinter = this.accounts[0];
      await this.token.connect(this.admin).grantRole(MINTER_ROLE, newMinter.address);
      expect(await this.token.hasRole(MINTER_ROLE, newMinter.address)).to.be.true;
    });

    it('non-admin cannot grant roles', async function () {
      await expect(
        this.token.connect(this.holder).grantRole(MINTER_ROLE, this.accounts[0].address)
      ).to.be.reverted;
    });
  });

  // ─── mint ─────────────────────────────────────────────────────────────────

  describe('mint', function () {
    it('minter can mint tokens', async function () {
      const enc = await encryptAmount(this.token.target, this.minter.address, 1000);
      await expect(
        this.token.connect(this.minter)['mint(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      )
        .to.emit(this.token, 'Mint')
        .withArgs(this.minter.address, this.holder.address, anyValue);
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(1000n);
    });

    it('minter can mint with a pre-encrypted handle', async function () {
      const tx = await this.factory.connect(this.minter).makeFor(this.token.target, 750);
      const receipt = await tx.wait();
      const amountHandle = getHandleFromReceipt(this.factory, receipt);
      await this.token.connect(this.minter)['mint(address,bytes32)'](this.holder.address, amountHandle);
      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, balanceHandle, this.holder)).to.equal(750n);
    });

    it('non-minter cannot mint tokens', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 1000);
      await expect(
        this.token.connect(this.holder)['mint(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.reverted;
    });

    it('cannot mint to frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.minter.address, 1000);
      await expect(
        this.token.connect(this.minter)['mint(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('cannot mint when contract is deactivated', async function () {
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.admin).deactivateContract();
      const enc = await encryptAmount(this.token.target, this.minter.address, 1000);
      await expect(
        this.token.connect(this.minter)['mint(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  // ─── burn ─────────────────────────────────────────────────────────────────

  describe('burn', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('burner can burn tokens', async function () {
      const enc = await encryptAmount(this.token.target, this.burner.address, 500);
      await expect(
        this.token.connect(this.burner)['burn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.emit(this.token, 'Burn')
        .withArgs(this.burner.address, this.holder.address, anyValue);
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(500n);
    });

    it('burner can burn with a pre-encrypted handle', async function () {
      const tx = await this.factory.connect(this.burner).makeFor(this.token.target, 200);
      const receipt = await tx.wait();
      const amountHandle = getHandleFromReceipt(this.factory, receipt);
      await this.token.connect(this.burner)['burn(address,bytes32)'](
        this.holder.address, amountHandle
      );
      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, balanceHandle, this.holder)).to.equal(800n);
    });

    it('non-burner cannot burn tokens', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 500);
      await expect(
        this.token.connect(this.holder)['burn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.reverted;
    });

    it('cannot burn from frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.burner.address, 500);
      await expect(
        this.token.connect(this.burner)['burn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  // ─── pause ────────────────────────────────────────────────────────────────

  describe('pause', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('pauser can pause', async function () {
      await this.token.connect(this.pauser).pause();
      expect(await this.token.paused()).to.be.true;
    });

    it('pauser can unpause', async function () {
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.pauser).unpause();
      expect(await this.token.paused()).to.be.false;
    });

    it('non-pauser cannot pause', async function () {
      await expect(this.token.connect(this.holder).pause()).to.be.reverted;
    });

    it('transfers are blocked when paused', async function () {
      await this.token.connect(this.pauser).pause();
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('mint is allowed when paused', async function () {
      await this.token.connect(this.pauser).pause();
      await mint(this.token, this.minter, this.recipient, 500);
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(500n);
    });

    it('burn is allowed when paused', async function () {
      await this.token.connect(this.pauser).pause();
      const enc = await encryptAmount(this.token.target, this.burner.address, 500);
      await this.token.connect(this.burner)['burn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(500n);
    });

    it('operator transfers are blocked when paused', async function () {
      const expirationTimestamp = Math.floor(Date.now() / 1000) + 86400;
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, expirationTimestamp);
      await this.token.connect(this.pauser).pause();
      const enc = await encryptAmount(this.token.target, this.accounts[0].address, 100);
      await expect(
        this.token.connect(this.accounts[0])['confidentialTransferFrom(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  // ─── freeze ───────────────────────────────────────────────────────────────

  describe('freeze', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('enforcer can freeze an address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      expect(await this.token.isFrozen(this.holder.address)).to.be.true;
    });

    it('enforcer can unfreeze an address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      expect(await this.token.isFrozen(this.holder.address)).to.be.false;
    });

    it('non-enforcer cannot freeze', async function () {
      await expect(
        this.token.connect(this.holder).setAddressFrozen(this.recipient.address, true)
      ).to.be.reverted;
    });

    it('frozen address cannot transfer', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('cannot transfer to frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.recipient.address, true);
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });
  });

  // ─── forcedTransfer ──────────────────────────────────────────────────────

  describe('forcedTransfer', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('enforcer can force transfer from frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 500);
      await expect(
        this.token.connect(this.enforcer)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.emit(this.token, 'ForcedTransfer')
        .withArgs(this.enforcer.address, this.holder.address, this.recipient.address, anyValue);
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(500n);
    });

    it('enforcer can force transfer with a pre-encrypted handle', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const tx = await this.factory.connect(this.enforcer).makeFor(this.token.target, 300);
      const receipt = await tx.wait();
      const amountHandle = getHandleFromReceipt(this.factory, receipt);
      await this.token.connect(this.enforcer)['forcedTransfer(address,address,bytes32)'](
        this.holder.address, this.recipient.address, amountHandle
      );
      const balanceHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, balanceHandle, this.recipient)).to.equal(300n);
    });

    it('cannot force transfer from non-frozen address', async function () {
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 500);
      await expect(
        this.token.connect(this.enforcer)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('non-enforcer cannot force transfer', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.holder.address, 500);
      await expect(
        this.token.connect(this.holder)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.reverted;
    });

    it('cannot force transfer to address(0)', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 500);
      await expect(
        this.token.connect(this.enforcer)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, ethers.ZeroAddress, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_AddressZeroNotAllowed');
    });

    it('enforcer can force transfer even when contract is deactivated', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.admin).deactivateContract();
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 500);
      await this.token.connect(this.enforcer)['forcedTransfer(address,address,bytes32,bytes)'](
        this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
      );
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(500n);
    });
  });

  // ─── forcedBurn ──────────────────────────────────────────────────────────

  describe('forcedBurn', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('enforcer can force burn from frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 500);
      await expect(
        this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.emit(this.token, 'ForcedBurn')
        .withArgs(this.enforcer.address, this.holder.address, anyValue);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(500n);
    });

    it('enforcer can force burn with a pre-encrypted handle', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const tx = await this.factory.connect(this.enforcer).makeFor(this.token.target, 250);
      const receipt = await tx.wait();
      const amountHandle = getHandleFromReceipt(this.factory, receipt);
      await this.token.connect(this.enforcer)['forcedBurn(address,bytes32)'](
        this.holder.address, amountHandle
      );
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, balanceHandle, this.holder)).to.equal(750n);
    });

    it('enforcer can force burn all tokens from frozen address', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 1000);
      await this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(0n);
    });

    it('cannot force burn from non-frozen address', async function () {
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 500);
      await expect(
        this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('non-enforcer cannot force burn', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.holder.address, 500);
      await expect(
        this.token.connect(this.holder)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.reverted;
    });

    it('enforcer can force burn even when contract is deactivated', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.admin).deactivateContract();
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 500);
      await this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(500n);
    });

    it('force burn with amount exceeding balance burns 0', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 2000);
      await this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(1000n);
    });
  });

  // ─── transfer ────────────────────────────────────────────────────────────

  describe('transfer', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('holder can transfer tokens', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 400);
      await this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
        this.recipient.address, enc.handles[0], enc.inputProof
      );
      const recipientHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, recipientHandle, this.recipient)).to.equal(400n);
      const holderHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, holderHandle, this.holder)).to.equal(600n);
    });

    it('holder can transfer with a pre-encrypted handle', async function () {
      const tx = await this.factory.connect(this.holder).makeFor(this.token.target, 350);
      const receipt = await tx.wait();
      const amountHandle = getHandleFromReceipt(this.factory, receipt);
      await this.token.connect(this.holder)['confidentialTransfer(address,bytes32)'](
        this.recipient.address, amountHandle
      );
      const recipientHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, recipientHandle, this.recipient)).to.equal(350n);
      const holderHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, holderHandle, this.holder)).to.equal(650n);
    });

    it('transfer with insufficient balance transfers 0', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 2000);
      await this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
        this.recipient.address, enc.handles[0], enc.inputProof
      );
      const recipientHandle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, recipientHandle, this.recipient)).to.equal(0n);
      const holderHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, holderHandle, this.holder)).to.equal(1000n);
    });
  });

  // ─── transfer and call ────────────────────────────────────────────────

  describe('transferAndCall', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      this.receiver = await ethers.deployContract('ConfidentialReceiverMock', [true]);
    });

    it('holder can transferAndCall to a compliant receiver', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 200);
      await this.token.connect(this.holder)['confidentialTransferAndCall(address,bytes32,bytes,bytes)'](
        this.receiver.target, enc.handles[0], enc.inputProof, '0x'
      );
      const holderHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, holderHandle, this.holder)).to.equal(800n);
    });

    it('transferAndCall refunds when receiver rejects', async function () {
      await this.receiver.setAccept(false);
      const enc = await encryptAmount(this.token.target, this.holder.address, 200);
      await this.token.connect(this.holder)['confidentialTransferAndCall(address,bytes32,bytes,bytes)'](
        this.receiver.target, enc.handles[0], enc.inputProof, '0x'
      );
      const holderHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, holderHandle, this.holder)).to.equal(1000n);
    });

    it('operator can transferFromAndCall', async function () {
      const exp = Math.floor(Date.now() / 1000) + 86400;
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, exp);
      const enc = await encryptAmount(this.token.target, this.accounts[0].address, 150);
      await this.token.connect(this.accounts[0])['confidentialTransferFromAndCall(address,address,bytes32,bytes,bytes)'](
        this.holder.address, this.receiver.target, enc.handles[0], enc.inputProof, '0x'
      );
      const holderHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, holderHandle, this.holder)).to.equal(850n);
    });
  });

  // ─── operator ────────────────────────────────────────────────────────────

  describe('operator', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('holder can set operator', async function () {
      const exp = Math.floor(Date.now() / 1000) + 86400;
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, exp);
      expect(await this.token.isOperator(this.holder.address, this.accounts[0].address)).to.be.true;
    });

    it('operator can transfer on behalf of holder', async function () {
      const exp = Math.floor(Date.now() / 1000) + 86400;
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, exp);
      const enc = await encryptAmount(this.token.target, this.accounts[0].address, 300);
      await this.token.connect(this.accounts[0])['confidentialTransferFrom(address,address,bytes32,bytes)'](
        this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
      );
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(300n);
    });

    it('expired operator cannot transfer', async function () {
      const exp = Math.floor(Date.now() / 1000) - 1;
      await this.token.connect(this.holder).setOperator(this.accounts[0].address, exp);
      const enc = await encryptAmount(this.token.target, this.accounts[0].address, 300);
      await expect(
        this.token.connect(this.accounts[0])['confidentialTransferFrom(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'ERC7984UnauthorizedSpender');
    });
  });
}
