// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title ScreeningRuleEngineMock
 * @dev Minimal RuleEngine mock that screens transfers, mints and burns by address
 * (KYC/sanctions-style). Used to exercise audit finding M-01: mint/burn must be
 * screened by the RuleEngine in `CMTATConfidentialRuleEngine`.
 *
 * A blocked address is rejected on any leg of a transfer. Mint passes
 * `from = address(0)` and burn passes `to = address(0)`; the zero address is never
 * blocked, so issuance/redemption to a permitted counterparty succeeds while a
 * mint to — or burn from — a blocked address reverts. Not suitable for production.
 */
contract ScreeningRuleEngineMock {
    mapping(address account => bool) public blocked;

    /// @dev Number of times `transferred` (either overload) has been invoked.
    /// Lets tests assert that mint/burn fire the RuleEngine notification (M-01).
    uint256 public transferredCount;

    error ScreeningRuleEngineMock_Blocked(address from, address to);

    function setBlocked(address account, bool value) external {
        blocked[account] = value;
    }

    /* ============ View screening ============ */

    function canTransfer(
        address from,
        address to,
        uint256 /*value*/
    ) public view returns (bool) {
        return !blocked[from] && !blocked[to];
    }

    function canTransferFrom(
        address spender,
        address from,
        address to,
        uint256 /*value*/
    ) public view returns (bool) {
        return !blocked[spender] && !blocked[from] && !blocked[to];
    }

    /* ============ State-changing notification ============ */

    function transferred(
        address spender,
        address from,
        address to,
        uint256 value
    ) external {
        if (!canTransferFrom(spender, from, to, value)) {
            revert ScreeningRuleEngineMock_Blocked(from, to);
        }
        transferredCount += 1;
    }

    function transferred(
        address from,
        address to,
        uint256 value
    ) external {
        if (!canTransfer(from, to, value)) {
            revert ScreeningRuleEngineMock_Blocked(from, to);
        }
        transferredCount += 1;
    }
}
