# Contributing

Contributions are much welcomed and appreciated.
Here are a few guidelines to help you get started:

## Code Guidelines
- If you add a new option, document it in the vim help file. Documenting it in the `README.md` is NOT sufficient (and not even needed for most options). Take a look at `doc/tpipeline.txt` and document in a similar style. You can generate a help tag later with `:helptags ALL`.
- Never change basic vim options (for example `:h fillchars`) just because they make more sense for you. Plugins should never overwrite unrelated settings.
- Only add comments if they bring extra info to the table, don't just reiterate obvious code
- Often good variable names are much more worth than comments
- If you need more than 10 seconds to understand a single line of code, then absolutely DO add a comment
- If you implement a feature only for Neovim, write it in such an abstract way that it is easy to add a Vim implementation later

## Testing
Always run the testing suite before submitting a patch, so that you don't break any functionality.
For more info about this take a look at the documentation in `tests/README.md`.

Similarly, if your patch fixes a bug, it would be good if you can add a test that fails before your patch and passes after your patch.
You can take a look at some existing test files to help you get started.
