import { expect } from 'chai';
import { ethers } from 'hardhat';
import { deployToken, TOKEN_NAME, TOKEN_SYMBOL } from './helpers/deploy';

const TOKEN_ATTRIBUTE_ROLE = ethers.keccak256(ethers.toUtf8Bytes('TOKEN_ATTRIBUTE_ROLE'));

function runTokenAttributeTests() {
  describe('initial state', function () {
    it('name and symbol are set from constructor values', async function () {
      expect(await this.token.name()).to.equal(TOKEN_NAME);
      expect(await this.token.symbol()).to.equal(TOKEN_SYMBOL);
    });
  });

  describe('setName', function () {
    it('role holder can update name', async function () {
      await this.token.connect(this.admin).setName('New Token Name');
      expect(await this.token.name()).to.equal('New Token Name');
    });

    it('emits Name event', async function () {
      await expect(this.token.connect(this.admin).setName('Renamed'))
        .to.emit(this.token, 'Name')
        .withArgs('Renamed', 'Renamed');
    });

    it('unauthorized caller cannot update name', async function () {
      await expect(this.token.connect(this.holder).setName('Hack')).to.be.reverted;
    });

    it('TOKEN_ATTRIBUTE_ROLE can be granted to a non-admin', async function () {
      await this.token.connect(this.admin).grantRole(TOKEN_ATTRIBUTE_ROLE, this.holder.address);
      await this.token.connect(this.holder).setName('Delegated Name');
      expect(await this.token.name()).to.equal('Delegated Name');
    });
  });

  describe('setSymbol', function () {
    it('role holder can update symbol', async function () {
      await this.token.connect(this.admin).setSymbol('NTK');
      expect(await this.token.symbol()).to.equal('NTK');
    });

    it('emits Symbol event', async function () {
      await expect(this.token.connect(this.admin).setSymbol('RNM'))
        .to.emit(this.token, 'Symbol')
        .withArgs('RNM', 'RNM');
    });

    it('unauthorized caller cannot update symbol', async function () {
      await expect(this.token.connect(this.holder).setSymbol('HCK')).to.be.reverted;
    });
  });
}

describe('ERC7984TokenAttributeModule', function () {
  describe('CMTATConfidential', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidential');
      Object.assign(this, ctx);
      await this.token.connect(this.admin).grantRole(TOKEN_ATTRIBUTE_ROLE, this.admin.address);
    });
    runTokenAttributeTests();
  });

  describe('CMTATConfidentialLite', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidentialLite');
      Object.assign(this, ctx);
      await this.token.connect(this.admin).grantRole(TOKEN_ATTRIBUTE_ROLE, this.admin.address);
    });
    runTokenAttributeTests();
  });

  describe('CMTATConfidentialRuleEngine', function () {
    beforeEach(async function () {
      const signers = await ethers.getSigners();
      const ruleEngine = await ethers.deployContract('RuleEngineMock', [signers[8].address]);
      const ctx = await deployToken('CMTATConfidentialRuleEngine', 6, [ruleEngine.target]);
      Object.assign(this, ctx);
      await this.token.connect(this.admin).grantRole(TOKEN_ATTRIBUTE_ROLE, this.admin.address);
    });
    runTokenAttributeTests();
  });

  describe('CMTATConfidentialWhitelist', function () {
    beforeEach(async function () {
      const ctx = await deployToken('CMTATConfidentialWhitelist');
      Object.assign(this, ctx);
      await this.token.connect(this.admin).grantRole(TOKEN_ATTRIBUTE_ROLE, this.admin.address);
    });
    runTokenAttributeTests();
  });
});
