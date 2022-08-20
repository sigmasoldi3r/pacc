# pacc
Package manager for CC: Tweaked and monorepo.

## Contributing

You can help expanding the package ecosystem!

Feel free to contribute at any time. To make your packages available just open a pull request.

Once the pull request is approved, it should appear available to the `pacc` command.

### Example

This is an example of a package called `cat`, which adds the `cat` command to your computer.

This example file would be placed at `cat/v1.0.0/package.lua`, for example.

```lua
--[[{
  "author": "sigmasoldier",
  "dependencies": {}
}]]

for _, v in pairs{...} do
  local file = io.open(v, 'r')
  print(file:read'*all')
  file:close()
end
```

Note that this is a very simplified example.

Dependency map should follow the `"name": "version"` pattern, where version can be an exact version, or a version with GLOB like patterns.

```json
{
  "dependencies": {
    "pandora": "*"
  }
}
```

This for example means that the package should download `pandora`, any version of it (Hence the `*` is used).
