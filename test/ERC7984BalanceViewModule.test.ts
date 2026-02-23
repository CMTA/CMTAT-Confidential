import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';

const name = 'CMTATFHE Token';
const symbol = 'CMTATFHE';
const contractURI = 'https://example.com/metadata';
const tokenId = 'TOKEN-001';
const terms = {
  name: 'Terms Document',
  uri: 'https://example.com/terms',
  documentHash: ethers.ZeroHash,
};
const information = 'Test token information';

const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('MINTER_ROLE'));
const OBSERVER_ROLE = ethers.keccak256(ethers.toUtf8Bytes('OBSERVER_ROLE'));

// Mint tokens to a target address
async function mint(token: any, minter: any, to: any, amount: number) {
  const encryptedInput = await fhevm
    .createEncryptedInput(token.target, minter.address)
    .add64(amount)
    .encrypt();
  await token
    .connect(minter)
    ['mint(address,bytes32,bytes)'](to.address, encryptedInput.handles[0], encryptedInput.inputProof);
}

// Decrypt a handle using a given signer (verifies the signer has ACL access)
async function decrypt(token: any, handle: bigint, signer: any): Promise<bigint> {
  return fhevm.userDecryptEuint(FhevmType.euint64, handle, token.target, signer);
}

describe('ERC7984BalanceViewModule (dual-observer)', function () {
  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    const [admin, minter, observerManager, holder, recipient, holderObserver, roleObserver, other] = accounts;

    this.admin = admin;
    this.minter = minter;
    this.observerManager = observerManager;
    this.holder = holder;
    this.recipient = recipient;
    this.holderObserver = holderObserver;
    this.roleObserver = roleObserver;
    this.other = other;

    const extraInfoAttributes = { tokenId, terms, information };

    this.token = await ethers.deployContract('CMTATFHE', [
      name,
      symbol,
      contractURI,
      admin.address,
      extraInfoAttributes,
    ]);

    await this.token.connect(admin).grantRole(MINTER_ROLE, minter.address);
    await this.token.connect(admin).grantRole(OBSERVER_ROLE, observerManager.address);
  });

  // ─────────────────────────────────────────────
  // 1. Holder observer (ERC7984ObserverAccess)
  // ─────────────────────────────────────────────
  describe('holder observer (setObserver)', function () {
    it('holder can set their own observer', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);
      expect(await this.token.observer(this.holder.address)).to.equal(this.holderObserver.address);
    });

    it('emits ERC7984ObserverAccessObserverSet', async function () {
      await expect(
        this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address),
      )
        .to.emit(this.token, 'ERC7984ObserverAccessObserverSet')
        .withArgs(this.holder.address, ethers.ZeroAddress, this.holderObserver.address);
    });

    it('observer gets ACL on existing balance immediately when set', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await decrypt(this.token, handle, this.holderObserver);
      expect(balance).to.equal(1000n);
    });

    it('observer gets ACL on balance after mint (_update re-grant)', async function () {
      // Observer set before any balance exists — no immediate ACL grant possible
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);
      // _update on mint re-grants ACL to the observer
      await mint(this.token, this.minter, this.holder, 500);

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await decrypt(this.token, handle, this.holderObserver);
      expect(balance).to.equal(500n);
    });

    it('existing observer can abdicate (set to address(0))', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);
      await this.token.connect(this.holderObserver).setObserver(this.holder.address, ethers.ZeroAddress);
      expect(await this.token.observer(this.holder.address)).to.equal(ethers.ZeroAddress);
    });

    it('non-holder cannot set observer', async function () {
      await expect(
        this.token.connect(this.other).setObserver(this.holder.address, this.other.address),
      ).to.be.revertedWithCustomError(this.token, 'Unauthorized');
    });

    it('existing observer cannot replace themselves with another address (only abdicate)', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);
      await expect(
        this.token.connect(this.holderObserver).setObserver(this.holder.address, this.other.address),
      ).to.be.revertedWithCustomError(this.token, 'Unauthorized');
    });
  });

  // ─────────────────────────────────────────────
  // 2. Role observer (ERC7984BalanceViewModule)
  // ─────────────────────────────────────────────
  describe('role observer (setRoleObserver / removeRoleObserver)', function () {
    it('observer manager can set a role observer', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);
      expect(await this.token.roleObserver(this.holder.address)).to.equal(this.roleObserver.address);
    });

    it('emits RoleObserverSet on setRoleObserver', async function () {
      await expect(
        this.token.connect(this.observerManager).setRoleObserver(this.holder.address, this.roleObserver.address),
      )
        .to.emit(this.token, 'RoleObserverSet')
        .withArgs(
          this.holder.address,
          ethers.ZeroAddress,
          this.roleObserver.address,
          this.observerManager.address,
        );
    });

    it('role observer gets ACL on existing balance immediately when set', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await decrypt(this.token, handle, this.roleObserver);
      expect(balance).to.equal(1000n);
    });

    it('role observer gets ACL on balance after mint (_update re-grant)', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);
      await mint(this.token, this.minter, this.holder, 750);

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await decrypt(this.token, handle, this.roleObserver);
      expect(balance).to.equal(750n);
    });

    it('observer manager can remove a role observer', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);
      await this.token.connect(this.observerManager).removeRoleObserver(this.holder.address);
      expect(await this.token.roleObserver(this.holder.address)).to.equal(ethers.ZeroAddress);
    });

    it('emits RoleObserverSet with address(0) on removeRoleObserver', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);
      await expect(this.token.connect(this.observerManager).removeRoleObserver(this.holder.address))
        .to.emit(this.token, 'RoleObserverSet')
        .withArgs(
          this.holder.address,
          this.roleObserver.address,
          ethers.ZeroAddress,
          this.observerManager.address,
        );
    });

    it('unauthorized caller cannot call setRoleObserver', async function () {
      await expect(
        this.token.connect(this.other).setRoleObserver(this.holder.address, this.roleObserver.address),
      ).to.be.reverted;
    });

    it('unauthorized caller cannot call removeRoleObserver', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);
      await expect(
        this.token.connect(this.other).removeRoleObserver(this.holder.address),
      ).to.be.reverted;
    });

    it('reverts SameRoleObserver when setting the same observer again', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);
      await expect(
        this.token
          .connect(this.observerManager)
          .setRoleObserver(this.holder.address, this.roleObserver.address),
      ).to.be.revertedWithCustomError(this.token, 'ERC7984BalanceViewModule_SameRoleObserver');
    });

    it('reverts SameRoleObserver when removeRoleObserver called with no observer set', async function () {
      await expect(
        this.token.connect(this.observerManager).removeRoleObserver(this.holder.address),
      ).to.be.revertedWithCustomError(this.token, 'ERC7984BalanceViewModule_SameRoleObserver');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 3. _update: both observers get ACL on updated handles
  // ─────────────────────────────────────────────────────────────
  describe('_update: ACL re-granted after transfer', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('holder observer gets ACL on updated sender balance after transfer', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);

      const encInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(300)
        .encrypt();
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          encInput.handles[0],
          encInput.inputProof,
        );

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await decrypt(this.token, handle, this.holderObserver);
      expect(balance).to.equal(700n); // 1000 - 300
    });

    it('role observer gets ACL on updated sender balance after transfer', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);

      const encInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(400)
        .encrypt();
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          encInput.handles[0],
          encInput.inputProof,
        );

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      const balance = await decrypt(this.token, handle, this.roleObserver);
      expect(balance).to.equal(600n); // 1000 - 400
    });

    it('both observers independently get ACL on updated balances after transfer', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);

      const encInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(200)
        .encrypt();
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          encInput.handles[0],
          encInput.inputProof,
        );

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      const balanceViaHolderObs = await decrypt(this.token, handle, this.holderObserver);
      const balanceViaRoleObs = await decrypt(this.token, handle, this.roleObserver);

      expect(balanceViaHolderObs).to.equal(800n); // 1000 - 200
      expect(balanceViaRoleObs).to.equal(800n);
    });

    it('observers on recipient get ACL on updated balance after transfer', async function () {
      await this.token
        .connect(this.recipient)
        .setObserver(this.recipient.address, this.holderObserver.address);
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.recipient.address, this.roleObserver.address);

      const encInput = await fhevm
        .createEncryptedInput(this.token.target, this.holder.address)
        .add64(500)
        .encrypt();
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          encInput.handles[0],
          encInput.inputProof,
        );

      const handle = await this.token.confidentialBalanceOf(this.recipient.address);
      const balanceViaHolderObs = await decrypt(this.token, handle, this.holderObserver);
      const balanceViaRoleObs = await decrypt(this.token, handle, this.roleObserver);

      expect(balanceViaHolderObs).to.equal(500n);
      expect(balanceViaRoleObs).to.equal(500n);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 4. Independence: neither role can touch the other's slot
  // ─────────────────────────────────────────────────────────────────────
  describe('observer slot independence', function () {
    it('setRoleObserver does not affect the holder observer slot', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);

      expect(await this.token.observer(this.holder.address)).to.equal(this.holderObserver.address);
    });

    it('setObserver does not affect the role observer slot', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);

      expect(await this.token.roleObserver(this.holder.address)).to.equal(this.roleObserver.address);
    });

    it('OBSERVER_ROLE holder cannot overwrite the holder observer via setRoleObserver', async function () {
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);

      // Sets the role observer slot only — holder slot is untouched
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.other.address);

      expect(await this.token.observer(this.holder.address)).to.equal(this.holderObserver.address);
      expect(await this.token.roleObserver(this.holder.address)).to.equal(this.other.address);
    });

    it('holder cannot overwrite the role observer via setObserver', async function () {
      await this.token
        .connect(this.observerManager)
        .setRoleObserver(this.holder.address, this.roleObserver.address);

      // Sets the holder observer slot only — role slot is untouched
      await this.token.connect(this.holder).setObserver(this.holder.address, this.holderObserver.address);

      expect(await this.token.roleObserver(this.holder.address)).to.equal(this.roleObserver.address);
      expect(await this.token.observer(this.holder.address)).to.equal(this.holderObserver.address);
    });
  });
});
