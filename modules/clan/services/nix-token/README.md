# nix-token

Service module for managing and appending access-tokens in Nix configurations.

## Features

- Securely manages access-tokens for services like GitHub, GitLab, Codeberg, etc. for Nix configuration

## Usage

```nix
roles.default.tags.all = {};
roles.default.settings = {
  share = true; # Set to true if tokens should be shared across hosts
};
```

On activation, you will be prompted to paste your tokens in the format:

```
github=ghp_xxx gitlab=glpat-xxx codeberg=cbt_xxx
```

## Options

- `share` (bool): Whether to share the generated access-token file with other hosts. Default: `false`.

## Security

Tokens are stored as secrets and are not shared unless explicitly enabled.
