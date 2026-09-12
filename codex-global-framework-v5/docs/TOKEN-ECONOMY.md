# Token economy

The framework optimizes total work, not merely the model name:

- trivial tasks run directly because delegation has context and synthesis cost;
- Luna performs one targeted exploration pass for large unfamiliar codebases;
- stronger agents receive a compact context capsule instead of rescanning;
- only the difficult subtask escalates;
- review depth follows risk;
- environment, permission, and credential blockers never trigger model escalation;
- the hook adds one short reminder rather than duplicating routing logic.

The final usage table counts actual subagent executions. It is not token or
credit telemetry. Different executions can consume very different amounts, so
the framework never converts execution share into claimed token share.
