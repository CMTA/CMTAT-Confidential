import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  deployToken,
  mint,
  encryptAmount,
  decryptBalance,
  PAUSER_ROLE,
  ENFORCER_ROLE,
  BURNER_ROLE,
  FORCED_OPS_ROLE,
  TOKEN_NAME,
  TOKEN_SYMBOL,
  CONTRACT_URI,
  EXTRA_INFO,
  RULE_ENGINE_ROLE,
} from './helpers/deploy';
import { runCoreTests } from './helpers/core-tests';

describe('CMTATConfidentialRuleEngine', function () {
  beforeEach(async function () {
    const signers = await ethers.getSigners();
    this.authorizedOperator = signers[8];
    this.unauthorizedOperator = signers[9];
    this.ruleEngine = await ethers.deployContract('RuleEngineMock', [
      this.authorizedOperator.address,
    ]);
    const ctx = await deployToken('CMTATConfidentialRuleEngine', 6, [
      this.ruleEngine.target,
    ]);
    Object.assign(this, ctx);
    await this.token
      .connect(this.admin)
      .grantRole(RULE_ENGINE_ROLE, this.admin.address);
  });

  runCoreTests();

  describe('rule engine', function () {
    beforeEach(async function () {
      await mint(this.token, this.minter, this.holder, 1000);
    });

    it('stores the initial rule engine', async function () {
      expect(await this.token.ruleEngine()).to.equal(this.ruleEngine.target);
    });

    it('rule engine manager can update the rule engine', async function () {
      const nextRuleEngine = await ethers.deployContract('RuleEngineMock', [
        this.authorizedOperator.address,
      ]);

      await expect(
        this.token.connect(this.admin).setRuleEngine(nextRuleEngine.target)
      )
        .to.emit(this.token, 'RuleEngine')
        .withArgs(nextRuleEngine.target);

      expect(await this.token.ruleEngine()).to.equal(nextRuleEngine.target);
    });

    it('non-manager cannot update the rule engine', async function () {
      const nextRuleEngine = await ethers.deployContract('RuleEngineMock', [
        this.authorizedOperator.address,
      ]);

      await expect(
        this.token.connect(this.holder).setRuleEngine(nextRuleEngine.target)
      ).to.be.reverted;
    });

    it('reverts when setting the same rule engine', async function () {
      await expect(
        this.token.connect(this.admin).setRuleEngine(this.ruleEngine.target)
      ).to.be.revertedWithCustomError(
        this.token,
        'ERC7984RuleEngineModule_SameRuleEngine'
      );
    });

    it('can disable rule engine checks by setting address zero', async function () {
      await this.token.connect(this.admin).setRuleEngine(ethers.ZeroAddress);

      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          enc.handles[0],
          enc.inputProof
        );

      const recipientHandle = await this.token.confidentialBalanceOf(
        this.recipient.address
      );
      expect(
        await decryptBalance(this.token.target, recipientHandle, this.recipient)
      ).to.equal(100n);
    });

    it('exposes canTransfer with value zero semantics', async function () {
      expect(
        await this.token.canTransfer(
          this.holder.address,
          this.recipient.address,
          1
        )
      ).to.equal(true);
      expect(
        await this.token.canTransfer(
          this.holder.address,
          this.recipient.address,
          ethers.MaxUint256
        )
      ).to.equal(true);
    });

    it('canTransfer returns false when contract is paused', async function () {
      await this.token.connect(this.pauser).pause();
      expect(
        await this.token.canTransfer(this.holder.address, this.recipient.address, 1)
      ).to.equal(false);
    });

    it('canTransfer returns false when sender is frozen', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      expect(
        await this.token.canTransfer(this.holder.address, this.recipient.address, 1)
      ).to.equal(false);
    });

    it('exposes canTransferFrom through the rule engine with value zero semantics', async function () {
      expect(
        await this.token.canTransferFrom(
          this.authorizedOperator.address,
          this.holder.address,
          this.recipient.address,
          ethers.MaxUint256
        )
      ).to.equal(true);
      expect(
        await this.token.canTransferFrom(
          this.unauthorizedOperator.address,
          this.holder.address,
          this.recipient.address,
          ethers.MaxUint256
        )
      ).to.equal(false);
    });

    it('allows holder transfers when CMTAT RuleEngine amount rule would reject the encrypted amount but receives zero', async function () {
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);

      await this.token
        .connect(this.holder)
        ['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address,
          enc.handles[0],
          enc.inputProof
        );

      const recipientHandle = await this.token.confidentialBalanceOf(
        this.recipient.address
      );
      expect(
        await decryptBalance(this.token.target, recipientHandle, this.recipient)
      ).to.equal(100n);
    });

    it('blocks operator transfers through CMTAT RuleEngineMock.transferred when spender is not authorized', async function () {
      const exp = BigInt(
        (await ethers.provider.getBlock('latest'))!.timestamp + 3600
      );
      await this.token
        .connect(this.holder)
        .setOperator(this.unauthorizedOperator.address, exp);

      const enc = await encryptAmount(
        this.token.target,
        this.unauthorizedOperator.address,
        100
      );

      await expect(
        this.token
          .connect(this.unauthorizedOperator)
          ['confidentialTransferFrom(address,address,bytes32,bytes)'](
            this.holder.address,
            this.recipient.address,
            enc.handles[0],
            enc.inputProof
          )
      )
        .to.be.revertedWithCustomError(this.ruleEngine, 'RuleEngine_InvalidTransfer')
        .withArgs(this.holder.address, this.recipient.address, 0);
    });

    it('allows authorized operator transfers when CMTAT RuleEngineMock receives value zero', async function () {
      const exp = BigInt(
        (await ethers.provider.getBlock('latest'))!.timestamp + 3600
      );
      await this.token
        .connect(this.holder)
        .setOperator(this.authorizedOperator.address, exp);
      const enc = await encryptAmount(
        this.token.target,
        this.authorizedOperator.address,
        100
      );

      await this.token
        .connect(this.authorizedOperator)
        ['confidentialTransferFrom(address,address,bytes32,bytes)'](
          this.holder.address,
          this.recipient.address,
          enc.handles[0],
          enc.inputProof
        );

      const recipientHandle = await this.token.confidentialBalanceOf(
        this.recipient.address
      );
      expect(
        await decryptBalance(this.token.target, recipientHandle, this.recipient)
      ).to.equal(100n);
    });

    it('blocks transfer when paused even if rule engine allows it', async function () {
      await this.token.connect(this.pauser).pause();
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'ERC7943CannotTransfer');
    });

    it('blocks transfer when sender is frozen even if rule engine allows it', async function () {
      await this.token.connect(this.enforcer).setAddressFrozen(this.holder.address, true);
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await expect(
        this.token.connect(this.holder)['confidentialTransfer(address,bytes32,bytes)'](
          this.recipient.address, enc.handles[0], enc.inputProof
        )
      ).to.be.revertedWithCustomError(this.token, 'ERC7943CannotTransfer');
    });

    it('confidentialTransferAndCall is blocked by rule engine for unauthorized operator', async function () {
      const receiver = await ethers.deployContract('ConfidentialReceiverMock', [true]);
      const exp = BigInt((await ethers.provider.getBlock('latest'))!.timestamp + 3600);
      await this.token.connect(this.holder).setOperator(this.unauthorizedOperator.address, exp);
      const enc = await encryptAmount(this.token.target, this.unauthorizedOperator.address, 100);
      await expect(
        this.token.connect(this.unauthorizedOperator)['confidentialTransferFromAndCall(address,address,bytes32,bytes,bytes)'](
          this.holder.address, receiver.target, enc.handles[0], enc.inputProof, '0x'
        )
      ).to.be.revertedWithCustomError(this.ruleEngine, 'RuleEngine_InvalidTransfer');
    });

    it('confidentialTransferAndCall succeeds when rule engine allows it', async function () {
      const receiver = await ethers.deployContract('ConfidentialReceiverMock', [true]);
      const enc = await encryptAmount(this.token.target, this.holder.address, 100);
      await this.token.connect(this.holder)['confidentialTransferAndCall(address,bytes32,bytes,bytes)'](
        receiver.target, enc.handles[0], enc.inputProof, '0x'
      );
      const holderHandle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(await decryptBalance(this.token.target, holderHandle, this.holder)).to.equal(900n);
    });
  });

  // ─── M-01: RuleEngine screening applied to mint and burn ──────────────────────
  //
  // Regression tests for audit finding M-01. Before the fix, mint/burn skipped the
  // RuleEngine entirely, so issuance to — or redemption from — a non-whitelisted /
  // sanctioned address succeeded even though a confidentialTransfer to the same
  // address would revert. The fix wires RuleEngine screening into
  // _validateMint / _validateBurn (RuleEngine variant only) while leaving forced
  // operations to intentionally bypass the engine.
  describe('rule engine screening on mint/burn (M-01)', function () {
    beforeEach(async function () {
      this.screening = await ethers.deployContract('ScreeningRuleEngineMock');
      const ctx = await deployToken('CMTATConfidentialRuleEngine', 6, [
        this.screening.target,
      ]);
      Object.assign(this, ctx);
      await this.token
        .connect(this.admin)
        .grantRole(RULE_ENGINE_ROLE, this.admin.address);
    });

    async function burn(token: any, burner: any, from: any, amount: number) {
      const enc = await encryptAmount(token.target, burner.address, amount);
      await token
        .connect(burner)
        ['burn(address,bytes32,bytes)'](from.address, enc.handles[0], enc.inputProof);
    }

    it('mint to an allowed address succeeds and notifies the rule engine', async function () {
      await mint(this.token, this.minter, this.holder, 1000);

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(
        await decryptBalance(this.token.target, handle, this.holder)
      ).to.equal(1000n);
      // transferred() fired once for the mint notification
      expect(await this.screening.transferredCount()).to.equal(1n);
    });

    it('mint to a blocked address reverts (previously succeeded)', async function () {
      await this.screening.setBlocked(this.holder.address, true);

      const enc = await encryptAmount(this.token.target, this.minter.address, 1000);
      await expect(
        this.token
          .connect(this.minter)
          ['mint(address,bytes32,bytes)'](
            this.holder.address,
            enc.handles[0],
            enc.inputProof
          )
      )
        .to.be.revertedWithCustomError(this.token, 'ERC7943CannotReceive')
        .withArgs(this.holder.address);
    });

    it('burn from an allowed address succeeds and notifies the rule engine', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      const countAfterMint = await this.screening.transferredCount();

      await burn(this.token, this.burner, this.holder, 400);

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(
        await decryptBalance(this.token.target, handle, this.holder)
      ).to.equal(600n);
      expect(await this.screening.transferredCount()).to.equal(
        countAfterMint + 1n
      );
    });

    it('burn from a blocked address reverts (previously succeeded)', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.screening.setBlocked(this.holder.address, true);

      const enc = await encryptAmount(this.token.target, this.burner.address, 400);
      await expect(
        this.token
          .connect(this.burner)
          ['burn(address,bytes32,bytes)'](
            this.holder.address,
            enc.handles[0],
            enc.inputProof
          )
      )
        .to.be.revertedWithCustomError(this.token, 'ERC7943CannotSend')
        .withArgs(this.holder.address);
    });

    it('forced burn from a blocked (and frozen) address still bypasses the rule engine', async function () {
      await mint(this.token, this.minter, this.holder, 1000);
      await this.screening.setBlocked(this.holder.address, true);
      await this.token
        .connect(this.enforcer)
        .setAddressFrozen(this.holder.address, true);

      const enc = await encryptAmount(
        this.token.target,
        this.forcedOpsAgent.address,
        400
      );
      await this.token
        .connect(this.forcedOpsAgent)
        ['forcedBurn(address,bytes32,bytes)'](
          this.holder.address,
          enc.handles[0],
          enc.inputProof
        );

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(
        await decryptBalance(this.token.target, handle, this.holder)
      ).to.equal(600n);
    });

    it('mint/burn succeed when the rule engine is disabled (address zero)', async function () {
      await this.token.connect(this.admin).setRuleEngine(ethers.ZeroAddress);
      await this.screening.setBlocked(this.holder.address, true);

      // even though the holder is blocked in the (now-detached) screening engine,
      // disabling the engine allows issuance again
      await mint(this.token, this.minter, this.holder, 1000);
      await burn(this.token, this.burner, this.holder, 250);

      const handle = await this.token.confidentialBalanceOf(this.holder.address);
      expect(
        await decryptBalance(this.token.target, handle, this.holder)
      ).to.equal(750n);
    });

    it('base CMTAT freeze check still applies on top of rule engine screening', async function () {
      // recipient is allowed by the rule engine but frozen by CMTAT: the base
      // _validateMint layer must still reject before the engine is consulted
      await this.token
        .connect(this.enforcer)
        .setAddressFrozen(this.holder.address, true);

      const enc = await encryptAmount(this.token.target, this.minter.address, 1000);
      await expect(
        this.token
          .connect(this.minter)
          ['mint(address,bytes32,bytes)'](
            this.holder.address,
            enc.handles[0],
            enc.inputProof
          )
      )
        .to.be.revertedWithCustomError(this.token, 'ERC7943CannotReceive')
        .withArgs(this.holder.address);
    });
  });

  describe('decimals configuration', function () {
    it('uses configured decimals for CMTATConfidentialRuleEngine', async function () {
      const [, , , , , , , authorizedOperator] = await ethers.getSigners();
      const ruleEngine = await ethers.deployContract('RuleEngineMock', [
        authorizedOperator.address,
      ]);
      const { token } = await deployToken('CMTATConfidentialRuleEngine', 3, [
        ruleEngine.target,
      ]);
      expect(await token.decimals()).to.equal(3);
    });

    it('reverts with CMTAT_DecimalsTooHigh when decimals > 18', async function () {
      const [admin] = await ethers.getSigners();
      const ruleEngine = await ethers.deployContract('RuleEngineMock', [
        admin.address,
      ]);
      const factory = await ethers.getContractFactory(
        'CMTATConfidentialRuleEngine'
      );

      await expect(
        factory.deploy(
          TOKEN_NAME,
          TOKEN_SYMBOL,
          CONTRACT_URI,
          19,
          admin.address,
          EXTRA_INFO,
          ruleEngine.target
        )
      )
        .to.be.revertedWithCustomError(factory, 'CMTAT_DecimalsTooHigh')
        .withArgs(19);
    });
  });
});
