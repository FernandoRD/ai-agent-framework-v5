$output = @{
    hookSpecificOutput = @{
        hookEventName = "UserPromptSubmit"
        additionalContext = "For engineering work, enforce the loaded global AGENTS.md routing policy; Skills are optional."
    }
}
$output | ConvertTo-Json -Depth 3 -Compress
