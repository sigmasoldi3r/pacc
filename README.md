# pacc

Package manager for CC: Tweaked and monorepo for official packages.

## Contributing

You can help expanding the package ecosystem!

Feel free to contribute at any time. To make your packages available just open a pull request.

Once the pull request is approved, it should appear available to the `pacc` command.

### Examples

Two example packages are exist: [hello](hello) and [greeter](greeter).

#### Creating your own packages

This is an example of a package called `hi` that adds the command `hi` to your computer.

This example file would be placed at `hi/hi.lua`, and would contain:

```lua
print 'Hi!'
```

And you would add a file called `hi/info.json`, note that **this is mandatory**, as the package won't install otherwise.

```json
{
  "author": "Your name here",
  "description": "Although optional, you should add one.",
  "files": [ "hi.lua" ]
}
```

The field `"files"` is needed, or the package will fail to install.

Note that this is a very simplified example.

#### Using dependencies

You might want to make your package depend on others

## No versioning?

No. Originally, this package manager was being built to support semantic versioning, but after some iterations, the decision of dropping
versioning was choosen. Why? For two main reasons:

- It makes it difficult to maintain properly for casual users, and adds too much boilerplate
- The dependency management makes the complexity escalate, and the user-end file system would be bloated with files and folders.

So in order to simplify installations, mainteinance and creation of packages, and the program itself, versioning is dropped.

### So what if breaking changes?

You have a simple solution: For major changes just create a new package with the major version (Example, `hi` and `hi2` or `hi-2`).
