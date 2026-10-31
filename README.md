# From brief to pull request, with your own chief of staff

Four hours, one product per group, one system that grows hour by hour.

## Start

You need a POSIX shell, git and gh. The graph and the workshop scripts are shell scripts:
nothing to install, no build step. The app each group builds is a web page (HTML, CSS,
JavaScript), and its tests run in Chrome or Edge without a window, so a browser is the only
thing a laptop needs besides git and gh (and sqlite3 for hour 4).

1. Clone this repository.
2. Open Copilot in it: `copilot` in the repository's folder, or the Copilot app on that
   folder. In the app, choose **Local repository** in the dropdown under the prompt box,
   not a new worktree: everything the chief writes must land in the folder you cloned. When
   it asks to run a command, allow it for the session.
3. Open a terminal in the same folder. Your chief runs the commands and shows you every
   step as it happens; if you would rather type them yourselves, say so, and it gives
   them to you one at a time.
4. It greets you and asks your group number. It is your chief of staff: it tells you the
   story of your product and asks you the first decision.

## During the hour

Talk to your chief. Ask it what a word from the talk means, or for a hint when you are
stuck. The time is kept in the room, not by your chief. If you want to move on, it starts
the next hour from the prepared base; your work is kept in `mine-hour-<hour>/`. When it
hands a ticket to a worker or runs a ticket through your graph, it opens a terminal panel
so you watch it live.

## Your group's site

Every pull request merged into `main` that changes your app is published on your group's
own site, a minute later, when the app's tests are green:
`https://<owner>.github.io/<repo>/group-<N>/` (for this repository, the owner and the name
in its address on GitHub). Each group has its own workflow, `.github/workflows/group-<N>.yml`,
that only your folder triggers; a red test publishes nothing and your site keeps the last
green app. The page at `https://<owner>.github.io/<repo>/` lists the groups.

## Go deeper

- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) · Anthropic
- [The chief of staff agent](https://platform.claude.com/cookbook/claude-agent-sdk-01-the-chief-of-staff-agent) · Claude Agent SDK
- [Orchestrating subagents with dynamic workflows](https://github.com/anthropics/claude-cookbooks/blob/main/claude_agent_sdk/08_Dynamic_workflows.ipynb) · Claude Agent SDK
- [From issue to pull request with managed agents](https://github.com/anthropics/claude-cookbooks/blob/main/managed_agents/CMA_orchestrate_issue_to_pr.ipynb) · Claude
- [Building evals](https://github.com/anthropics/claude-cookbooks/blob/main/misc/building_evals.ipynb) and [agent memory](https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/memory_cookbook.ipynb) · Claude cookbooks
