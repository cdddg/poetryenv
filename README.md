# Simple Poetry Version Management: poetryenv

A pyenv-style Poetry version manager that helps you switch between different Poetry versions across multiple projects.

Inspired by [python-poetry/poetry#4235](https://github.com/python-poetry/poetry/issues/4235) and the follow-up [discussion #7866](https://github.com/orgs/python-poetry/discussions/7866), where the community discussed the need for managing multiple Poetry versions. While asdf or pipx provide general solutions, poetryenv offers a dedicated pyenv-style workflow specifically for Poetry.

> **Use Case**: If you only maintain one project, use the official Poetry installer. poetryenv is for managing multiple projects with different Poetry versions (e.g., legacy projects on 1.8.x, new projects on 2.x, or testing version upgrades).

---

## Installation

### Using Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/cdddg/poetryenv/main/install.sh | bash
```

> Installs to `~/.local` by default. Ensure `~/.local/bin` is in your `PATH`.

### Manual Installation

```bash
git clone https://github.com/cdddg/poetryenv.git ~/.poetryenv-src
cd ~/.poetryenv-src
PREFIX=$HOME/.local ./install.sh
```

### Setup Shell Integration

Add the following to your `~/.zshrc` or `~/.bashrc`:

```bash
eval "$(poetryenv init - zsh)"    # for zsh
eval "$(poetryenv init - bash)"   # for bash
```

Then reload your shell:

```bash
exec $SHELL
```

---

## Quick Start

1. **List available versions**

   ```bash
   poetryenv install --list
   ```

2. **Install and set global version**

   ```bash
   poetryenv install 1.8.5
   poetryenv global 1.8.5
   ```

3. **Set project-specific version**

   ```bash
   cd /path/to/project
   poetryenv local 1.7.1
   ```

4. **Verify current version**
   ```bash
   poetryenv version    # Shows: 1.7.1 (set by .poetry-version)
   ```

---

## Command Reference

| Command                            | Description                                 |
| :--------------------------------- | :------------------------------------------ |
| `poetryenv install <version>...`   | Install one or more Poetry versions         |
| `poetryenv install --list`         | List available versions from PyPI           |
| `poetryenv uninstall <version>...` | Remove one or more installed versions       |
| `poetryenv global [version]`       | Show or set global version                  |
| `poetryenv local [version]`        | Show or set the project's `.poetry-version` |
| `poetryenv local --unset`          | Remove project `.poetry-version`            |
| `poetryenv version`                | Show active version and source              |
| `poetryenv versions`               | List all installed versions                 |
| `poetryenv which`                  | Show path to active poetry executable       |
| `poetryenv --version`              | Show poetryenv version                      |

---

## .poetry-version Behavior

- The `.poetry-version` file in a project directory overrides the global setting
- Recommended to commit this file to version control (Git) to ensure team consistency
- Use `poetryenv local --unset` or delete the file to revert to global setting

---

## Troubleshooting

- **Command not found**

  ```bash
  export PATH="$HOME/.local/bin:$PATH"
  eval "$(poetryenv init - zsh)"
  ```

- **Installation fails** - Check dependencies

  ```bash
  python3 --version  # Requires Python 3.7+
  curl --version
  ```

- **Tab completion not working**
  ```bash
  exec $SHELL
  ```

---

## Update & Removal

**Update poetryenv:**

```bash
curl -fsSL https://raw.githubusercontent.com/cdddg/poetryenv/main/install.sh | bash
```

**Remove poetryenv:**

```bash
rm -rf ~/.poetryenv ~/.local/bin/poetryenv ~/.local/bin/poetry ~/.local/share/poetryenv
# Then remove the 'poetryenv init' line from your shell startup file
```

---

## Advanced: Version Isolation

Each Poetry version is completely isolated with separate config/data/cache directories:

```
~/.poetryenv/
├── global                          # Global version setting
└── versions/
    ├── 1.8.5/
    │   ├── bin/poetry
    │   ├── config/                 # Version-specific config
    │   ├── data/                   # Version-specific data
    │   └── cache/                  # Version-specific cache
    └── 2.0.1/
        └── ...
```

When switching versions, these environment variables are automatically set:

- `POETRY_CONFIG_DIR`
- `POETRY_DATA_DIR`
- `POETRY_CACHE_DIR`
