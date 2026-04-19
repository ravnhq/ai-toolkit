ADDITIONAL CONTEXT: The file being analyzed is a SKILL definition file (SKILL.md).
Skill definitions encode multi-step workflows, argument contracts, and user interaction patterns.
Focus scenarios on testing SKILL-specific compliance:
- Does the workflow execute steps in the documented order?
- Are user confirmation checkpoints honored (e.g., asking before proceeding)?
- Does progress reporting happen BEFORE long operations, not after?
- Are all documented arguments parsed and handled correctly?
- Are error messages actionable per the Troubleshooting section?
- Do Examples match the actual behavior described in the workflow?
