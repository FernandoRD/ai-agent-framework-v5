# API automation

Verify version, authentication method, privileges, target scope, filters, and expected counts. API writes are approval-gated: dry-run first, record prior state, use idempotent behavior where possible, read back results, and do not blindly retry ambiguous mutations.
