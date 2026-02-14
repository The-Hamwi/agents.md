# AGENTS.md

![AGENTS.md logo](./public/og.png)

[AGENTS.md](https://agents.md) is a simple, open format for guiding coding agents.

Think of AGENTS.md as a README for agents: a dedicated, predictable place
to provide context and instructions to help AI coding agents work on your project.

Below is a minimal example of an AGENTS.md file:

```markdown
# Sample AGENTS.md file

## Dev environment tips
- Use `pnpm dlx turbo run where <project_name>` to jump to a package instead of scanning with `ls`.
- Run `pnpm install --filter <project_name>` to add the package to your workspace so Vite, ESLint, and TypeScript can see it.
- Use `pnpm create vite@latest <project_name> -- --template react-ts` to spin up a new React + Vite package with TypeScript checks ready.
- Check the name field inside each package's package.json to confirm the right name—skip the top-level one.

## Testing instructions
- Find the CI plan in the .github/workflows folder.
- Run `pnpm turbo run test --filter <project_name>` to run every check defined for that package.
- From the package root you can just call `pnpm test`. The commit should pass all tests before you merge.
- To focus on one step, add the Vitest pattern: `pnpm vitest run -t "<test name>"`.
- Fix any test or type errors until the whole suite is green.
- After moving files or changing imports, run `pnpm lint --filter <project_name>` to be sure ESLint and TypeScript rules still pass.
- Add or update tests for the code you change, even if nobody asked.

## PR instructions
- Title format: [<project_name>] <Title>
- Always run `pnpm lint` and `pnpm test` before committing.
```

## Website

This repository also includes a basic Next.js website hosted at https://agents.md/
that explains the project’s goals in a simple way, and featuring some examples.

### Running the app locally
1. Install dependencies:
   ```bash
   pnpm install
   ```
2. Start the development server:
   ```bash
   pnpm run dev
   ```
3. Open your browser and go to http://localhost:3000

## Pre-push sanitization and quality gates

This repository uses a Git `pre-push` hook to reduce accidental secret leaks and enforce baseline quality checks before code reaches GitHub.

### Install hooks

```bash
npm run hooks:install
```

`npm install` also installs hooks automatically via the `prepare` script.

### What the gate blocks

- Sensitive file paths in pushed commits (for example `.env`, `.env.local`, `.envrc`, private keys, and key-store files).
- Added lines that look like real credentials (for example cloud keys, GitHub tokens, Slack tokens, private key material, JWT-like credentials, and credential-bearing URLs).

`*.env.example`, `*.env.sample`, and `*.env.template` are allowed as templates.

### Quality checks run before push

- `npm run typecheck` (required)
- `npm run lint` (when `lint` is configured and compatible with the installed Next.js version)
- `npm run test` (only when a `test` script exists)

### Verify the full gate setup

```bash
npm run gate:verify
```

### Enforce gate in GitHub (recommended)

This repo includes `.github/workflows/pre-push-gate-ci.yml`, which runs the same gate in GitHub Actions on `pull_request`, `push`, and merge-queue checks.

After pushing this workflow, configure branch protection (or rulesets) for your protected branch (for example `main`) and mark `pre-push-gate` as a **required status check**.

For the security policy, incident response runbooks, and roadmap, see:

- `SECURITY.md`
- `security/README.md`

### Run the gate manually (without pushing)

```bash
npm run prepush:check
```

### Handling intentional false positives

If a line is an intentional non-secret example, add `sanitization:allow` on that same line to bypass the content-pattern gate for that line only.
