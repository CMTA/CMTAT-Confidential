// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title ScreeningRuleEngineMock
 * @dev RuleEngine mock that screens transfers, mints and burns by address
 * (KYC/sanctions-style). Used to exercise audit finding M-01: mint/burn must be
 * screened by the RuleEngine in `CMTATConfidentialRuleEngine`.
 *
 * A blocked address is rejected on any leg it appears on. Following the CMTAT v3.3.0
 * convention (and production `RuleWhitelist`), the **spender is exempt for mint and
 * burn** (`from == address(0)` or `to == address(0)`): the operator is still forwarded
 * to `transferred` (recorded in `lastSpender`) but is not screened on those legs, so a
 * `MINTER_ROLE`/`BURNER_ROLE` holder can issue/redeem without being whitelisted, while a
 * blocked recipient (mint) or blocked holder (burn) is still rejected. For standard
 * transfers the spender is screened. Not suitable for production.
 */
contract ScreeningRuleEngineMock {
    mapping(address account => bool) public blocked;

    /// @dev Number of times `transferred` (either overload) has been invoked.
    /// Lets tests assert that mint/burn fire the RuleEngine notification (M-01).
    uint256 public transferredCount;

    /// @dev Spender seen by the most recent 4-arg `transferred` call. Lets tests assert
    /// that the operator is forwarded as spender on mint/burn (CMTAT v3.3.0 convention).
    address public lastSpender;

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
        uint256 value
    ) public view returns (bool) {
        // Mint (from == 0) and burn (to == 0) exempt the spender check, matching
        // production RuleWhitelist and the CMTAT v3.3.0 mint/burn spender convention.
        if (from != address(0) && to != address(0) && blocked[spender]) {
            return false;
        }
        return canTransfer(from, to, value);
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
        lastSpender = spender;
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
