import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import {
  deployToken,
  ENFORCER_ROLE,
  FORCED_OPS_ROLE,
  SUPPLY_OBSERVER_ROLE,
  mint,
  encryptAmount,
  decryptBalance,
} from './helpers/deploy';

describe('ERC7984EnforcementModule', function () {
  beforeEach(async function () {
    const ctx = await deployToken('CMTATConfidential');
    Object.assign(this, ctx);

    this.supplyManager = this.accounts[0];
    this.supplyObserver = this.accounts[1];

    await this.token.connect(this.admin).grantRole(SUPPLY_OBSERVER_ROLE, this.supplyManager.address);
  });

  async function decryptTotalSupply(token: any, signer: any): Promise<bigint> {
    const handle = await token.confidentialTotalSupply();
    return fhevm.userDecryptEuint(FhevmType.euint64, handle, token.target, signer);
  }

  function getHandleFromReceipt(factory: any, receipt: any): string {
    for (const log of receipt.logs) {
      try {
        const parsed = factory.interface.parseLog(log);
        if (parsed?.name === 'HandleCreated') return parsed.args.handle;
      } catch { /* ignore */ }
    }
    throw new Error('HandleCreated event not found');
  }

  // ─── role separation ─────────────────────────────────────────────────────────

  describe('role separation (ENFORCER_ROLE vs FORCED_OPS_ROLE)', function () {
    it('account with only ENFORCER_ROLE cannot forcedTransfer', async function () {
      const freezeOnly = this.accounts[2];
      await this.token.connect(this.admin).grantRole(ENFORCER_ROLE, freezeOnly.address);
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(freezeOnly).setAddressFrozen(this.holder.address, true);

      const enc = await encryptAmount(this.token.target, freezeOnly.address, 100);
      await expect(
        this.token.connect(freezeOnly)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.reverted;
    });

    it('account with only FORCED_OPS_ROLE cannot freeze', async function () {
      const forcedOnly = this.accounts[3];
      await this.token.connect(this.admin).grantRole(FORCED_OPS_ROLE, forcedOnly.address);
      await expect(
        this.token.connect(forcedOnly).setAddressFrozen(this.holder.address, true)
      ).to.be.reverted;
    });
  });

  // ─── forcedTransfer (externalEuint64) ────────────────────────────────────────

  describe('forcedTransfer (externalEuint64 overload)', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
    });

    it('FORCED_OPS_ROLE can forcedTransfer from a frozen address', async function () {
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 400);
      await this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32,bytes)'](
        this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
      );
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(400n);
    });

    it('unauthorized caller cannot forcedTransfer', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.reverted;
    });

    it('reverts CMTAT_AddressNotFrozen when address is not frozen', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 100);
      await expect(
        this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_AddressNotFrozen');
    });

    it('reverts CMTAT_Enforcement_ZeroAddressNotAllowed when to is address(0)', async function () {
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 100);
      await expect(
        this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, ethers.ZeroAddress, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_Enforcement_ZeroAddressNotAllowed');
    });

    it('emits ForcedTransfer with correct args', async function () {
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 400);
      await expect(
        this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32,bytes)'](
          this.holder.address, this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.emit(this.token, 'ForcedTransfer')
        .withArgs(this.forcedOpsAgent.address, this.holder.address, this.recipient.address, anyValue);
    });
  });

  // ─── forcedTransfer (euint64) ─────────────────────────────────────────────────

  describe('forcedTransfer (euint64 overload)', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      this.factory = await ethers.deployContract('Euint64Factory');
    });

    it('reverts ERC7984EnforcementModule_UnauthorizedHandle when caller lacks ACL', async function () {
      // use createEncryptedInput so the handle has ACL only for holder+token, never for
      // forcedOpsAgent — avoids cross-test ACL contamination from shared FHE counter state
      const enc = await encryptAmount(this.token.target, this.holder.address, 300);

      await expect(
        this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32)'](
          this.holder.address, this.recipient.address, enc.handles[0]
        )
      ).to.be.revertedWithCustomError(this.token, 'ERC7984EnforcementModule_UnauthorizedHandle');
    });

    it('FORCED_OPS_ROLE can forcedTransfer with a pre-encrypted handle', async function () {
      const tx = await this.factory.connect(this.forcedOpsAgent).makeFor(this.token.target, 300);
      const receipt = await tx.wait();
      const amountHandle = getHandleFromReceipt(this.factory, receipt);

      await this.token.connect(this.forcedOpsAgent)['forcedTransfer(address,address,bytes32)'](
        this.holder.address, this.recipient.address, amountHandle
      );
      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      expect(await decryptBalance(this.token.target, handle, this.recipient)).to.equal(300n);
    });
  });

  // ─── forcedBurn (externalEuint64) ────────────────────────────────────────────

  describe('forcedBurn (externalEuint64 overload)', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
    });

    it('FORCED_OPS_ROLE can forcedBurn from a frozen address', async function () {
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 400);
      await this.token.connect(this.forcedOpsAgent)['forcedBurn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );
    });

    it('unauthorized caller cannot forcedBurn', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.reverted;
    });

    it('reverts CMTAT_AddressNotFrozen when address is not frozen', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 100);
      await expect(
        this.token.connect(this.forcedOpsAgent)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_AddressNotFrozen');
    });

    it('emits ForcedBurn', async function () {
      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 400);
      await expect(
        this.token.connect(this.forcedOpsAgent)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.emit(this.token, 'ForcedBurn');
    });

    it('_afterBurn is called: total supply observers get ACL on new handle after forcedBurn', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.supplyObserver.address);

      const enc = await encryptAmount(this.token.target, this.forcedOpsAgent.address, 400);
      await this.token.connect(this.forcedOpsAgent)['forcedBurn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );

      const supply = await decryptTotalSupply(this.token, this.supplyObserver);
      expect(supply).to.equal(600n);
    });
  });

  // ─── forcedBurn (euint64) ─────────────────────────────────────────────────────

  describe('forcedBurn (euint64 overload)', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      this.factory = await ethers.deployContract('Euint64Factory');
    });

    it('_afterBurn is called: total supply observers get ACL on new handle after forcedBurn', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.supplyObserver.address);

      const tx = await this.factory.connect(this.forcedOpsAgent).makeFor(this.token.target, 200);
      const receipt = await tx.wait();
      const amountHandle = getHandleFromReceipt(this.factory, receipt);

      await this.token.connect(this.forcedOpsAgent)['forcedBurn(address,bytes32)'](
        this.holder.address, amountHandle
      );

      const supply = await decryptTotalSupply(this.token, this.supplyObserver);
      expect(supply).to.equal(800n);
    });

    it('reverts ERC7984EnforcementModule_UnauthorizedHandle when caller lacks ACL', async function () {
      // use createEncryptedInput so the handle has ACL only for holder+token, never for
      // forcedOpsAgent — avoids cross-test ACL contamination from shared FHE counter state
      const enc = await encryptAmount(this.token.target, this.holder.address, 200);

      await expect(
        this.token.connect(this.forcedOpsAgent)['forcedBurn(address,bytes32)'](
          this.holder.address, enc.handles[0]
        )
      ).to.be.revertedWithCustomError(this.token, 'ERC7984EnforcementModule_UnauthorizedHandle');
    });
  });
});
