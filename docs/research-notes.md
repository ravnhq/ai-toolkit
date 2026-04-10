## General AI/Agents:
- AGENTS.md guide: https://www.aihero.dev/a-complete-guide-to-agents-md
  - https://x.com/mattpocockuk/status/2012906065856270504
- Better plan mode: https://www.aihero.dev/my-agents-md-file-for-building-plans-you-actually-read
  - 
  - I want to take each step in the 4 step process and define for our team which agents, skills, mcp, etc are relevant in each phase
- Oh My Claude: https://github.com/TechDufus/oh-my-claude
- AskUserQuestionTool (Claude)
  - "Read this plan file and interview me in detail using AskUserQuestionTool about literally anything: technical implementation, UI & UX, concerns, tradeoffs, etc."
  - The important pieces are to make the plan (PRD.md, PLAN.md), document the progress (progress.txt)

- Claude Opus 4.5 has a 200K context window.
  - It's good to watch the context window and try not to go over 50%. Context poisoning starts to happen.


## Hooks

```json
"hooks": {
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "echo \"For context, today's date is $(date). Please use this as the current date for all time-relative questions.\""
        }
      ]
    }
  ]
}
```

## Skills

### General skill notes:
- "Description quality directly determines auto-invocation accuracy. Generic descriptions failed completely. But when I structured descriptions with a WHEN + WHEN NOT pattern, the skills were being invoked each time."

### Vercel Skills Platform:
- skills.sh
- They took the approach of symlinking to the .agents folder like I wanted to do. I think this is a good approach.

### Better Auth:
- https://x.com/bekacru/status/2012429803740348609
- npx skills add better-auth/skills

### React/Next.js
- Vercel React Best Practices: https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices
- Vercel React Best Practices Blog post: https://vercel.com/blog/introducing-react-best-practices

### Resources/Videos:
- Lee Robinson on Agents, Commands, Skills, MCP, etc: https://www.youtube.com/watch?v=L_p5GxGSB_I
- Anthrophic what is a skill: https://www.youtube.com/watch?v=fOxC44g8vig
- Anthrophic on Skills > Agents: https://www.youtube.com/watch?v=CEvIs9y1uog

### Design
- Vercel Web Interface Guidelines: https://vercel.com/design/guidelines
- https://www.ui-skills.com/
- https://www.rams.ai/