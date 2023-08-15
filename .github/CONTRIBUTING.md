# Contributing

## Issues and bug reports
When reporting issues, please include both your vim config and tmux config if relevant. If you don't know what parts of your config are relevant, it is okay to just paste your entire config.
Often it is also helpful to know what terminal emulator you are using.
When debugging statusline artifacts, it can be helpful to checkout `:echo tpipeline#debug#info()` or `:checkhealth tpipeline` in neovim.

## Development
Code contributions are much welcomed and appreciated.
Here are a few guidelines to help you get started:

### Code Guidelines
- If you add a new option, document it in the vim help file. Documenting it in the [README](/README.md) is NOT sufficient (and not even needed for most options). Take a look at [the existing helpfile](/doc/tpipeline.txt) and document in a similar style. You can generate a help tag later with [scripts/gen-helptags.sh](/scripts/gen-helptags.sh)
- Never change basic vim options (for example `:h fillchars`) just because they make more sense for you. Plugins should never overwrite unrelated settings
- Only add comments if they bring extra info to the table, don't just reiterate obvious code
- Often good variable names are much more worth than comments
- If you need more than 10 seconds to understand a single line of code, then absolutely DO add a comment
- If you implement a feature only for Neovim, write it in such an abstract way that it is easy to add a Vim implementation later

### Testing
Always run the testing suite before submitting a patch, so that you don't break any functionality.
For more info about this take a look at the [documentation](/tests/README.md).

Similarly, if your patch fixes a bug, it would be good if you can add a test that fails before your patch and passes after your patch.
You can take a look at some existing test files to help you get started.

### Submitting Patches
You can either submit your changes as a pull request on Github or send them via email to me. In the latter case make sure that your email client does not break the formatting of your patch, I recommend using `git send-email` for this.

### Developer's Certificate of Origin
By making a contribution to this project, I certify that:

1. The contribution was created in whole or in part by me and I have the right to submit it under the open source license indicated in the file; or
2. The contribution is based upon previous work that, to the best of my knowledge, is covered under an appropriate open source license and I have the right under that license to submit that work with modifications, whether created in whole or in part by me, under the same open source license (unless I am permitted to submit under a different license), as indicated in the file; or
3. The contribution was provided directly to me by some other person who certified (1), (2) or (3) and I have not modified it.
4. I understand and agree that this project and the contribution are public and that a record of the contribution (including all personal information I submit with it, including my sign-off) is maintained indefinitely and may be redistributed consistent with this project or the open source license(s) involved.
