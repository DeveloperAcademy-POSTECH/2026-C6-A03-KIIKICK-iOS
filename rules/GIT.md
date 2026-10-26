# Git Strategy

## Tag Conventions

`init` : first commit

`feat` : new feature

`fix` : fix bugs or errors

`docs` : edit README, templates and documents

`setting` : Project settings

`add` : add photos, assets and libraries

`refactor` : edit or refactor codes

`chore` : not important edit

## Commit Conventions

- Tags are required.
- Write commit messages in Korean.
- Keep the title under 50 characters, short and in the imperative mood. If more explanation is needed, add it in the description.

```markdown
[feat] 로그인 기능 구현
```

## Branch Conventions

tag/#issue_number- working_files or directory

```markdown
feat/#1-loginUI
```

## Branch Strategy

- `main`: Branch used for releases.
- `develop`: Branch where all developed features are merged and verified.
  - This is the default branch. All completed work must be merged into `develop`.
  - When you finish working on your branch, first merge `develop` into your branch, then open a pull request to `develop`.
  - Before merging, merge the latest `main` into your current branch and run a build to make sure there are no conflicts or build errors.
- `feature`: Refers to all tagged branches. All feature development, bug fixes, etc. must be done on these branches.