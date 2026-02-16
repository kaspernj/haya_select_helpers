Notes
- Be careful with Capybara waiting behavior in helper predicates. Methods called inside `wait_for_expect`/retry loops must use `wait: 0` for `has_selector?`/`has_no_selector?` checks to avoid multiplying wait time.
- Prefer `wait_for_selector` / `wait_for_no_selector` for intentional waiting, and keep predicate helpers non-blocking.
- Avoid layered waits (for example `has_selector?` followed by `wait_for_and_find` on the same selector with default wait).
- In specs, prefer explicit class names (e.g. `HayaSelect`) over `described_class`.
- Prefer `__send__(:method_name)` over `send(:method_name)`.
- In spec files, prefer `describe` over `RSpec.describe`.
