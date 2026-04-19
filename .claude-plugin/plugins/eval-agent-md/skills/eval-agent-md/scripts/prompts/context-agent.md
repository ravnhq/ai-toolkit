ADDITIONAL CONTEXT: The file being analyzed is an AGENT DEFINITION, not a CLAUDE.md.
Agent definitions define specialized roles with constrained capabilities.
Focus scenarios on testing ROLE BOUNDARIES:
- Does the agent stay within its declared scope?
- Does it avoid actions outside its tool set?
- Does it use the correct output format?
- Does it refuse to do things outside its role?

For example, a "reviewer" agent should suggest fixes but NOT write implementation code.
A "runner" agent should execute commands but NOT edit source files.
