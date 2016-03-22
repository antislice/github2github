# github2github
Move github issues to another github repo, but with ruby. And by label.

## Setup/Usage
This relies on the octokit gem, so either install it with `gem install octokit` or run `bundle install`. 

Right now, credentials are handled with a .netrc file, which needs to be installed with `gem install netrc` or the previously run `bundle install`. The default .netrc file is at `~/.netrc` and looks like this:
````
machine api.github.com
  login defunkt
  password c0d3b4ssssss!
````

The script expects all the issues you want to move to have the same label. Run with:
````
> ruby move_issues.rb source-repo target-repo label-on-issues-to-move
````
**You need to have push access to both repositories or the script will fail with 404s. Also, if your label has spaces remember to enclose it in quotes: `"my space label"`.**

### What it does
* Adds each issue labeled with `search-label` to the target repo, and adds a line at the bottom of the issue description about who originally filed it in the source repo
* If an issue has a label or milestone that doesn't exist in the target repo, that label or milestone is created in the target repo (*except* for `search-label`)
* All comments are moved over (in order) with a note about who originally made the comment
* The original issue is closed in the source repo with a comment indicating it was moved to the target repo
See [this issue](https://github.com/codeforamerica/nola-2016-fellows/issues/61) as an example of an issue that was moved with this script.

## Contributing
If you find a bug or have a feature to add, I'm happy to look at pull requests. Issues may or may not ever be addressed.

Testing: I recommend commenting out lines that affect the source repo (if working with an active repo), like the lines that add comments or close the source issue. Making a throwaway repo to use as a target for the new issues is also handy.

## Credits
This is inspired by [IQAndreas](https://github.com/IQAndreas)'s [github-issues-import](https://github.com/IQAndreas/github-issues-import), but it doesn't move issues by label and I don't have experience with Python. There's also [this google thing](https://github-issue-mover.appspot.com/) but it moves issues one at a time and doesn't copy over labels and milestones. Plus I did [pivotal2github](https://github.com/antislice/pivotal2github) a couple years ago & this seemed relatively straightforward.
