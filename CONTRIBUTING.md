# Contributing Guidelines

Thank you for your interest in contributing to this project!\
These guidelines help keep contributions consistent, maintainable, and
secure.

------------------------------------------------------------------------

## 📌 General Rules

1.  Be respectful and constructive in discussions, issues, and pull
    requests.
2.  Security-sensitive information (e.g., API keys, passwords, internal
    IPs) must **never** be committed.
3.  Use issues to propose major changes before creating a pull request
    (PR).
4.  All contributions should target the `main` or `dev` branch (see
    branching rules below).

------------------------------------------------------------------------

## 🛠 Development Setup

-   Use **Linux/macOS/WSL** where possible for consistency.
-   Ensure your code passes linting and formatting checks (`pre-commit`
    hooks are encouraged).
-   Keep scripts modular, reusable, and documented.

------------------------------------------------------------------------

## 🌱 Branching Strategy

-   `main`: Stable production-ready code.
-   `dev`: Active development and testing.
-   Feature branches: `feature/<short-description>`
-   Bugfix branches: `fix/<short-description>`

Example:

    feature/ansible-docker-role
    fix/proxmox-cloudinit-bug

------------------------------------------------------------------------

## 📝 Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/): -
`feat:` -- new feature - `fix:` -- bug fix - `docs:` -- documentation
only changes - `refactor:` -- code changes without altering
functionality - `test:` -- adding or updating tests - `chore:` --
maintenance tasks

Example:

    feat: add ansible role for docker install
    fix: correct cloud-init network config issue

------------------------------------------------------------------------

## ✅ Pull Requests

-   Keep PRs small and focused.
-   Reference related issues (`Closes #123`).
-   Update documentation if new features/configs are introduced.
-   All PRs require at least **1 review** before merge.

------------------------------------------------------------------------

## 🔒 Security & Automation Notes

-   No hardcoded secrets. Use environment variables or vault systems.
-   Test automation scripts in a **sandbox/lab environment** before PR
    submission.
-   Always check for backward compatibility with existing configs.

------------------------------------------------------------------------

## 📖 Documentation

-   Add usage notes in the `README.md` or a `docs/` folder.
-   Use clear comments in YAML, Ansible, Terraform, or bash scripts.
-   When possible, provide examples in the form of code snippets.

------------------------------------------------------------------------

## 🙌 Code of Conduct

This project follows the [Contributor
Covenant](https://www.contributor-covenant.org/).\
By contributing, you agree to uphold a positive and inclusive community.

------------------------------------------------------------------------

Thank you for helping improve this project 🚀
