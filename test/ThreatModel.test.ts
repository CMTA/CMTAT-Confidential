import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';
import {
  deployToken,
  PAUSER_ROLE,
  BURNER_ROLE,
  OBSERVER_ROLE,
  ALLOWLIST_ROLE,
  SUPPLY_OBSERVER_ROLE,
  mint,
  encryptAmount,
  decryptBalance,
} from './helpers/deploy';

/**
 * Threat-model verification suite.
 *
 * Each test references a threat ID from THREAT_MODEL.md and asserts the actual
 * runtime behaviour (finding evidence or invariant confirmation). See RESULT.md
 * for the disposition of every threat.
 *
 * Toolchain: Hardhat + @fhevm/hardhat-plugin mock coprocessor (FHE ops cannot run
 * under Foundry/forge). Property coverage uses parameterized loops over boundary
 * values rather than forge fuzzing.
 */
describe('ThreatModel verification', function () {
  async function decryptSupply(token: any, signer: any): Promise<bigint> {
    const handle = await token.confidentialTotalSupply();
    return fhevm.userDecryptEuint(FhevmType.euint64, handle, token.target, signer);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FHE-1 (Medium): observer can escalate scoped read access to GLOBAL public
  // disclosure via the inherited, non-overridden requestDiscloseEncryptedAmount.
  // ─────────────────────────────────────────────────────────────────────────
  describe('FHE-1: observer -> public disclosure escalation', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      this.observerManager = this.accounts[0];
      this.regObserver = this.accounts[1];
      this.outsider = this.accounts[2];
      await this.token.connect(this.admin).grantRole(OBSERVER_ROLE, this.observerManager.address);
      await mint(this.token, this.minter, this.holder, 5000);
    });

    it('a role observer can make the observed account balance PUBLICLY decryptable', async function () {
      // Compliance role assigns an observer over the victim without victim consent.
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.regObserver.address);

      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);

      // Sanity: an outsider with no ACL cannot user-decrypt the victim balance.
      await expect(
        decryptBalance(this.token.target, balanceHandle, this.outsider),
      ).to.be.rejected;

      // ESCALATION: the observer uses its ACL to make the handle world-decryptable.
      await this.token
        .connect(this.regObserver)
        .requestDiscloseEncryptedAmount(balanceHandle);

      // Now ANYONE (no ACL) can public-decrypt the victim's confidential balance.
      const cleartext = await fhevm.publicDecryptEuint(FhevmType.euint64, balanceHandle);
      expect(cleartext).to.equal(5000n);
    });

    it('a holder-set observer can likewise globally disclose the holder balance', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.regObserver.address);
      const balanceHandle = await this.token.confidentialBalanceOf(this.holder.address);
      await this.token.connect(this.regObserver).requestDiscloseEncryptedAmount(balanceHandle);
      const cleartext = await fhevm.publicDecryptEuint(FhevmType.euint64, balanceHandle);
      expect(cleartext).to.equal(5000n);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TX-3 (Low): mint/burn permitted while paused; blocked once deactivated.
  // ─────────────────────────────────────────────────────────────────────────
  describe('TX-3: mint/burn vs pause/deactivation', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
    });

    it('mint succeeds while the contract is paused', async function () {
      await this.token.connect(this.pauser).pause();
      expect(await this.token.paused()).to.be.true;
      await mint(this.token, this.minter, this.holder, 1000); // does not revert
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(1000n);
    });

    it('burn succeeds while the contract is paused', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.pauser).pause();
      const enc = await encryptAmount(this.token.target, this.burner.address, 400);
      await this.token.connect(this.burner)['burn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof,
      );
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, handle, this.holder)).to.equal(600n);
    });

    it('mint reverts once the contract is deactivated', async function () {
      await this.token.connect(this.pauser).pause();
      await this.token.connect(this.admin).deactivateContract();
      const enc = await encryptAmount(this.token.target, this.minter.address, 100);
      await expect(
        this.token.connect(this.minter)['mint(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TX-4 (Info): forced ops bypass pause (only the frozen precondition matters).
  // ─────────────────────────────────────────────────────────────────────────
  describe('TX-4: forced ops bypass pause', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      await this.token.connect(this.pauser).pause();
    });

    it('forcedTransfer executes from a frozen address while paused', async function () {
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 300);
      await this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32,bytes)'](
        this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof,
      );
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(300n);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TX-1 (Low): transfer/forcedTransfer of amount > balance saturates to 0.
  // ─────────────────────────────────────────────────────────────────────────
  describe('TX-1: silent zero on insufficient balance', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      await mint(this.token, this.minter, this.holder, 100);
    });

    it('standard transfer of more than balance moves 0 without reverting', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 1000);
      await this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
        this.recipient.address, enc.handles[0], enc.inputProof,
      );
      const fromH = await this.token.confidentialBalanceOf(this.holder.address);
      const toH = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, fromH, this.holder)).to.equal(100n);
      expect(await decryptBalance(this.token.target, toH, this.recipient)).to.equal(0n);
    });

    it('forcedTransfer of more than the frozen balance moves 0 without reverting', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 999);
      await this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32,bytes)'](
        this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof,
      );
      const fromH = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, fromH, this.holder)).to.equal(100n);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AC-1: every standard transfer overload is gated by freeze + pause.
  // ─────────────────────────────────────────────────────────────────────────
  describe('AC-1: transfer-gate completeness', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('confidentialTransfer reverts when sender is frozen', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.holder.address, 10);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });

    it('confidentialTransfer reverts when recipient is frozen', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.recipient.address, true);
      const enc = await encryptAmount(this.token.target, this.holder.address, 10);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });

    it('confidentialTransfer reverts while paused', async function () {
      await this.token.connect(this.pauser).pause();
      const enc = await encryptAmount(this.token.target, this.holder.address, 10);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });

    it('confidentialTransferFrom reverts when spender (operator) is frozen', async function () {
      const operator = this.accounts[0];
      const until = Math.floor(Date.now() / 1000) + 3600;
      await this.token.connect(this.holder).setOperator(operator.address, until);
      await this.token.connect(this.enforcer).setAddressFrozen(operator.address, true);
      const enc = await encryptAmount(this.token.target, operator.address, 10);
      await expect(
        this.token.connect(operator)['confidentialTransferFrom(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // POL-2: allowlist applies to every transfer overload + mint (Whitelist variant).
  // ─────────────────────────────────────────────────────────────────────────
  describe('POL-2: allowlist enforcement completeness (Whitelist variant)', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidentialWhitelist');
      Object.assign(this, ctx);
      this.allowlister = this.accounts[0];
      await this.token.connect(this.admin).grantRole(ALLOWLIST_ROLE, this.allowlister.address);
      await this.token.connect(this.allowlister).enableAllowlist(true);
      await this.token.connect(this.allowlister).setAddressAllowlist(this.holder.address, true);
      await this.token.connect(this.allowlister).setAddressAllowlist(this.minter.address, true);
    });

    it('mint to a non-allowlisted account reverts when allowlist enabled', async function () {
      const outsider = this.accounts[5];
      const enc = await encryptAmount(this.token.target, this.minter.address, 100);
      await expect(
        this.token.connect(this.minter)['mint(address,bytes32,bytes)'](
          outsider.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });

    it('transfer to a non-allowlisted recipient reverts when allowlist enabled', async function () {
      await mint(this.token, this.minter, this.holder, 500);
      const outsider = this.accounts[5];
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          outsider.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });

    it('transfer between two allowlisted accounts succeeds', async function () {
      await this.token.connect(this.allowlister).setAddressAllowlist(this.recipient.address, true);
      await mint(this.token, this.minter, this.holder, 500);
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
        this.recipient.address, enc.handles[0], enc.inputProof,
      );
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(100n);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TX-5 (invariant): observer ACL survives sequential transfers; supply
  // observer ACL survives mint/burn/mint.
  // ─────────────────────────────────────────────────────────────────────────
  describe('TX-5: observer-ACL invariants', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      this.observerManager = this.accounts[0];
      this.regObserver = this.accounts[1];
      this.supplyManager = this.accounts[2];
      this.supplyObserver = this.accounts[3];
      await this.token.connect(this.admin).grantRole(OBSERVER_ROLE, this.observerManager.address);
      await this.token.connect(this.admin).grantRole(SUPPLY_OBSERVER_ROLE, this.supplyManager.address);
    });

    it('role observer can decrypt the balance after several sequential transfers', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.observerManager).setRoleObserver(this.holder.address, this.regObserver.address);

      for (const amt of [100, 50, 25]) {
        const enc = await encryptAmount(this.token.target, this.holder.address, amt);
        await this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof,
        );
      }
      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      // ACL must still be valid for the observer on the latest handle.
      expect(await decryptBalance(this.token.target, handle, this.regObserver)).to.equal(825n);
    });

    it('supply observer keeps ACL across mint -> burn -> mint', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.supplyObserver.address);
      await mint(this.token, this.minter, this.holder, 1000);
      const encB = await encryptAmount(this.token.target, this.burner.address, 200);
      await this.token.connect(this.burner)['burn(address,bytes32,bytes)'](
        this.holder.address, encB.handles[0], encB.inputProof,
      );
      await mint(this.token, this.minter, this.recipient, 500);
      expect(await decryptSupply(this.token, this.supplyObserver)).to.equal(1300n);
    });

    it('setMaxSupplyObservers below current count reverts; cap is enforced', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.supplyObserver.address);
      await expect(
        this.token.connect(this.admin).setMaxSupplyObservers(0),
      ).to.be.revertedWithCustomError(this.token, 'ERC7984TotalSupplyViewModule_MaxBelowCurrentCount');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AC-2: authorization-hook negative coverage for privileged functions.
  // ─────────────────────────────────────────────────────────────────────────
  describe('AC-2: unauthorized callers are rejected', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      this.attacker = this.accounts[4];
    });

    it('non-minter cannot mint', async function () {
      const enc = await encryptAmount(this.token.target, this.attacker.address, 1);
      await expect(
        this.token.connect(this.attacker)['mint(address,bytes32,bytes)'](
          this.attacker.address, enc.handles[0], enc.inputProof,
        ),
      ).to.be.reverted;
    });

    it('non-pauser cannot pause', async function () {
      await expect(this.token.connect(this.attacker).pause()).to.be.reverted;
    });

    it('non-observer-manager cannot setRoleObserver', async function () {
      await expect(
        this.token.connect(this.attacker).setRoleObserver(this.holder.address, this.attacker.address),
      ).to.be.reverted;
    });

    it('non-publisher cannot publishTotalSupply', async function () {
      await mint(this.token, this.minter, this.holder, 100);
      await expect(this.token.connect(this.attacker).publishTotalSupply()).to.be.reverted;
    });

    it('non-supply-admin cannot setMaxSupplyObservers', async function () {
      await expect(this.token.connect(this.attacker).setMaxSupplyObservers(5)).to.be.reverted;
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // math + VIEW-1/POL-3: decimals guard and view-surface asymmetry.
  // ─────────────────────────────────────────────────────────────────────────
  describe('math / view surfaces', function () {
    it('constructor reverts when decimals > 18', async function () {
      await expect(deployToken('CMTATConfidential', 19)).to.be.reverted;
    });

    it('canSend may return true while canTransfer returns false under pause (POL-3 asymmetry)', async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      await this.token.connect(this.pauser).pause();
      expect(await this.token.canSend(this.holder.address)).to.be.true; // ignores pause
      expect(await this.token.canTransfer(this.holder.address, this.recipient.address, 0)).to.be.false; // reflects pause
    });
  });
});
