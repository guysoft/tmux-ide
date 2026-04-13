# Cross-Platform `sed -i` (In-Place Editing)

## Problem

`sed -i` behaves differently on macOS (BSD sed) vs Linux (GNU sed):

- **GNU sed (Linux):** `sed -i 's/old/new/' file` — no backup extension required
- **BSD sed (macOS):** `sed -i '' 's/old/new/' file` — requires a backup extension argument (use `''` for no backup)

Using the GNU syntax on macOS produces errors like:
```
sed: 1: "filename": invalid command code
```

Additionally, BSD sed's `i` (insert) and `a` (append) commands require different syntax:
- **GNU sed:** `sed -i '/pattern/i new line' file` (inline text)
- **BSD sed:** requires a backslash-newline after `i\` — the inline form does not work

## Solution: Helper Function

Add this function near the top of your shell script:

```bash
sed_inplace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}
```

Then replace all `sed -i` calls with `sed_inplace`:

```bash
# Before (broken on macOS):
sed -i 's/foo/bar/' file.txt

# After (works everywhere):
sed_inplace 's/foo/bar/' file.txt
```

## Inserting Lines: Use `awk` Instead of `sed`

For inserting lines before a pattern, avoid `sed`'s `i` command entirely. Use `awk`:

```bash
# Insert a line before a matching pattern (portable):
awk -v line="new line to insert" '/pattern/{print line}{print}' file > file.tmp && mv file.tmp file
```

This works identically on macOS and Linux.

## Notes

- `$OSTYPE` is a built-in bash variable. On macOS it is `darwin*`, on Linux it is `linux-gnu` (or similar).
- The function passes all arguments through via `"$@"`, so it works with any `sed` expression and flags.
- If your script uses `#!/bin/sh` (POSIX), use `uname` instead:
  ```sh
  sed_inplace() {
    if [ "$(uname)" = "Darwin" ]; then
      sed -i '' "$@"
    else
      sed -i "$@"
    fi
  }
  ```
