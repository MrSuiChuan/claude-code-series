# E2E Test Rules

- Prefer stable selectors such as roles, labels, and explicit test ids when needed.
- Keep tests focused on user journeys, not implementation details.
- Reuse fixtures and authenticated session setup where possible.
- Make each test independent and safe to rerun.
- When a flaky test appears, identify timing, network, or state leakage before adding waits.
