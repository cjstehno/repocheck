# repocheck

Tool for comparing contents of a local maven repository with a specified remote repository to determine missing artifacts.

> NOTE: For a more current version of this tool - see my [depdiff](https://github.com/cjstehno/depdiff) project.

## Usage

Run the check with:

    repocheck --local=/some/local/repo --remote=https://remote:1234/repo

Full help:

```
A tool for resolving differences between local and remote repos.
    --local Path to the local repo.
   --remote URL for the remote repo.
-h   --help This help information.
```

Running the tool will result in a list of maven coordinates for all of the artifacts that are in the local repo which are missing from the remote repo.

## Build

The project is written in the [D Programming Language](http://dlang.org) and may be built with:

    dub build --build=release

which will build the application as the `repocheck` executable in the project root directory.
