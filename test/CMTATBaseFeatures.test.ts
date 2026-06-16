import { expect } from 'chai';
import { ethers } from 'hardhat';
import { deployToken } from './helpers/deploy';

const EXTRA_INFORMATION_ROLE = ethers.keccak256(ethers.toUtf8Bytes('EXTRA_INFORMATION_ROLE'));
const DOCUMENT_ROLE = ethers.keccak256(ethers.toUtf8Bytes('DOCUMENT_ROLE'));

const DOC_NAME = ethers.encodeBytes32String('prospectus');
const DOC_URI = 'https://example.com/prospectus.pdf';
const DOC_HASH = ethers.keccak256(ethers.toUtf8Bytes('document content'));

describe('CMTATBaseFeatures', function () {
  beforeEach(async function () {
    const ctx = await deployToken('CMTATConfidential');
    Object.assign(this, ctx);

    await this.token.connect(this.admin).grantRole(EXTRA_INFORMATION_ROLE, this.admin.address);
    await this.token.connect(this.admin).grantRole(DOCUMENT_ROLE, this.admin.address);
  });

  // ─── Extra information ──────────────────────────────────────────────────────

  describe('setTerms', function () {
    it('role holder can set terms and read them back', async function () {
      const newTerms = {
        name: 'Prospectus v2',
        uri: 'https://example.com/prospectus-v2.pdf',
        documentHash: ethers.keccak256(ethers.toUtf8Bytes('v2 content')),
      };
      await this.token.connect(this.admin).setTerms(newTerms);

      const stored = await this.token.terms();
      expect(stored.name).to.equal(newTerms.name);
      expect(stored.doc.uri).to.equal(newTerms.uri);
      expect(stored.doc.documentHash).to.equal(newTerms.documentHash);
    });

    it('emits Terms event', async function () {
      const newTerms = {
        name: 'Prospectus v3',
        uri: 'https://example.com/prospectus-v3.pdf',
        documentHash: ethers.ZeroHash,
      };
      await expect(this.token.connect(this.admin).setTerms(newTerms)).to.emit(
        this.token,
        'Terms'
      );
    });

    it('unauthorized caller cannot set terms', async function () {
      await expect(
        this.token.connect(this.holder).setTerms({
          name: 'x',
          uri: 'https://example.com',
          documentHash: ethers.ZeroHash,
        })
      ).to.be.reverted;
    });
  });

  describe('setTokenId', function () {
    it('role holder can set tokenId and read it back', async function () {
      await this.token.connect(this.admin).setTokenId('ISIN-CH1234567890');
      expect(await this.token.tokenId()).to.equal('ISIN-CH1234567890');
    });

    it('emits TokenId event', async function () {
      await expect(
        this.token.connect(this.admin).setTokenId('ISIN-DE0001234560')
      ).to.emit(this.token, 'TokenId');
    });

    it('unauthorized caller cannot set tokenId', async function () {
      await expect(
        this.token.connect(this.holder).setTokenId('ISIN-HACK')
      ).to.be.reverted;
    });
  });

  describe('setInformation', function () {
    it('role holder can set information and read it back', async function () {
      await this.token.connect(this.admin).setInformation('Updated token info');
      expect(await this.token.information()).to.equal('Updated token info');
    });

    it('emits Information event', async function () {
      await expect(
        this.token.connect(this.admin).setInformation('New info')
      ).to.emit(this.token, 'Information');
    });

    it('unauthorized caller cannot set information', async function () {
      await expect(
        this.token.connect(this.holder).setInformation('hacked')
      ).to.be.reverted;
    });
  });

  // ─── Document management ────────────────────────────────────────────────────

  describe('document management', function () {
    it('role holder can add a document and retrieve it', async function () {
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);

      const doc = await this.token.getDocument(DOC_NAME);
      expect(doc.uri).to.equal(DOC_URI);
      expect(doc.documentHash).to.equal(DOC_HASH);
      expect(doc.lastModified).to.be.gt(0n);
    });

    it('getAllDocuments returns the registered document name', async function () {
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);

      const names = await this.token.getAllDocuments();
      expect(names).to.include(DOC_NAME);
    });

    it('setDocument emits DocumentUpdated event', async function () {
      await expect(
        this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH)
      ).to.emit(this.token, 'DocumentUpdated').withArgs(DOC_NAME, DOC_URI, DOC_HASH);
    });

    it('can update an existing document', async function () {
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);

      const newUri = 'https://example.com/updated.pdf';
      const newHash = ethers.keccak256(ethers.toUtf8Bytes('updated content'));
      await this.token.connect(this.admin).setDocument(DOC_NAME, newUri, newHash);

      const doc = await this.token.getDocument(DOC_NAME);
      expect(doc.uri).to.equal(newUri);
      expect(doc.documentHash).to.equal(newHash);
    });

    it('getAllDocuments does not duplicate on update', async function () {
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);
      await this.token
        .connect(this.admin)
        .setDocument(DOC_NAME, 'https://example.com/v2.pdf', ethers.ZeroHash);

      const names = await this.token.getAllDocuments();
      expect(names.filter((n: string) => n === DOC_NAME)).to.have.length(1);
    });

    it('can add multiple documents', async function () {
      const docB = ethers.encodeBytes32String('whitepaper');
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);
      await this.token
        .connect(this.admin)
        .setDocument(docB, 'https://example.com/whitepaper.pdf', ethers.ZeroHash);

      const names = await this.token.getAllDocuments();
      expect(names).to.include(DOC_NAME);
      expect(names).to.include(docB);
    });

    it('can remove a document', async function () {
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);
      await this.token.connect(this.admin).removeDocument(DOC_NAME);

      const names = await this.token.getAllDocuments();
      expect(names).to.not.include(DOC_NAME);
    });

    it('removeDocument emits DocumentRemoved event', async function () {
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);
      await expect(
        this.token.connect(this.admin).removeDocument(DOC_NAME)
      ).to.emit(this.token, 'DocumentRemoved').withArgs(DOC_NAME, DOC_URI, DOC_HASH);
    });

    it('removeDocument reverts for non-existent document', async function () {
      const missing = ethers.encodeBytes32String('nonexistent');
      await expect(
        this.token.connect(this.admin).removeDocument(missing)
      ).to.be.reverted;
    });

    it('unauthorized caller cannot add a document', async function () {
      await expect(
        this.token.connect(this.holder).setDocument(DOC_NAME, DOC_URI, DOC_HASH)
      ).to.be.reverted;
    });

    it('unauthorized caller cannot remove a document', async function () {
      await this.token.connect(this.admin).setDocument(DOC_NAME, DOC_URI, DOC_HASH);
      await expect(
        this.token.connect(this.holder).removeDocument(DOC_NAME)
      ).to.be.reverted;
    });

    it('DOCUMENT_ROLE can be granted to a non-admin', async function () {
      await this.token.connect(this.admin).grantRole(DOCUMENT_ROLE, this.holder.address);
      await this.token.connect(this.holder).setDocument(DOC_NAME, DOC_URI, DOC_HASH);

      const doc = await this.token.getDocument(DOC_NAME);
      expect(doc.uri).to.equal(DOC_URI);
    });

    it('EXTRA_INFORMATION_ROLE can be granted to a non-admin', async function () {
      await this.token
        .connect(this.admin)
        .grantRole(EXTRA_INFORMATION_ROLE, this.holder.address);
      await this.token.connect(this.holder).setTokenId('ISIN-DELEGATED');
      expect(await this.token.tokenId()).to.equal('ISIN-DELEGATED');
    });
  });
});
