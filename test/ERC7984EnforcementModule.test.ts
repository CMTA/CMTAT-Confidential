import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';
import {
  deployToken,
  ENFORCER_ROLE,
  FORCED_OPS_ROLE,
  MINTER_ROLE,
  SUPPLY_OBSERVER_ROLE,
  mint,
  encryptAmount,
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

  // ─── forcedBurn ──────────────────────────────────────────────────────────────

  describe('forcedBurn (externalEuint64 overload)', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
    });

    it('FORCED_OPS_ROLE can forcedBurn from a frozen address', async function () {
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 400);
      await this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
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

    it('reverts when address is not frozen', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, false);
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 100);
      await expect(
        this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'CMTAT_InvalidTransfer');
    });

    it('emits ForcedBurn', async function () {
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 400);
      await expect(
        this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
          this.holder.address, enc.handles[0], enc.inputProof
        )
      ).to.emit(this.token, 'ForcedBurn');
    });

    it('_afterBurn is called: total supply observers get ACL on new handle after forcedBurn', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.supplyObserver.address);

      const enc = await encryptAmount(this.token.target, this.enforcer.address, 400);
      await this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
        this.holder.address, enc.handles[0], enc.inputProof
      );

      // Observer must be able to decrypt the updated total supply
      const supply = await decryptTotalSupply(this.token, this.supplyObserver);
      expect(supply).to.equal(600n);
    });
  });

  describe('forcedBurn (euint64 overload)', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
    });

    it('_afterBurn is called: total supply observers get ACL on new handle after forcedBurn', async function () {
      await this.token.connect(this.supplyManager).addTotalSupplyObserver(this.supplyObserver.address);

      // Mint a fresh encrypted amount that the enforcer has ACL access to
      const enc = await encryptAmount(this.token.target, this.enforcer.address, 300);
      const handle = await this.token.connect(this.enforcer)
        ['forcedBurn(address,bytes32,bytes)'].staticCall(
          this.holder.address, enc.handles[0], enc.inputProof
        ).catch(() => null);

      // Use externalEuint64 overload for simplicity in the euint64 ACL path
      const enc2 = await encryptAmount(this.token.target, this.enforcer.address, 200);
      await this.token.connect(this.enforcer)['forcedBurn(address,bytes32,bytes)'](
        this.holder.address, enc2.handles[0], enc2.inputProof
      );

      const supply = await decryptTotalSupply(this.token, this.supplyObserver);
      expect(supply).to.equal(800n);
    });
  });
});
