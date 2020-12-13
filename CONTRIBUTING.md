Welcome to the contributor guide. If you can't find important information you're welcome
to edit this page or open a discussion issue to talk with maintainers.

In this guide you'll find informations about:
* [Bug reporting](#bug-reporting)
* [Development](#development)
* [Maintainer tasks](#maintainer-tasks)

### Bug reporting

Wordmove is an hard piece of software to debug and it is used by many users with many
different environments - Windows also, even if it isn't officially supported by the dev team.

So *please*, help the community adding some crucial informations and posting well
formatted code. Inspirational details:

* OS
* Ruby version
* Wordmove version
* Are you using system Ruby, rbenv or RVM?
* Describe at your best the action you required to Wordmove: push/pull, ftp/ssh
* Paste (safely) your full or partial `movefile.yml`
* Paste (safely) the entire trace of error/exception you encountered, if any
* If you paste code or the STDOUT log/trace **format them**. If it sound as a joke I swear I'm serious:
use GitHub's Markdown syntax to keep things readable if you'd like to discuss your problem with the community.
* Label the issue if you can

As a general advise: we tend to not support Wordmove's versions older than the latest stable.
We'd appreciate your help opening an in depth report if you'd find that an older version is working
better for you.

Thank you all for your support and for the love <3

### Development

#### Get Wordmove

* fork wordmove
* clone your own repo
* be sure to check-out the right branch, usually `master`

##### Installing Ruby

To install ruby, please, use [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://rvm.io).

##### Contribute

* run `bundle install` to install gem dependencies
* `git checkout -b my_feature_or_fix_name`
* code, commit, push and send a pull request on GitHub

> Version bump is considered to be a maintainer's task, so please leave the version
alone while working on your branch.


##### Test Wordmove

Wordmove has a decent test coverage. We _require_ that pull requests does not break tests launched by the CI.
In order to launch tests on you dev machine

```fish
rake
```

The command will launch the test suite - written with RSpec - and rubocop.

In order to use the gem locally you can install it

```fish
rake install
wordmove --version
```

or run the executable directly

```fish
bin/wordmove --version
```

#### Documenting

A large part of the code is documented using https://yardoc.org/.

Please, stick with this practice when you're implementing new code. If you want to preview yard
documentation locally

```
gem install yard
yard server -r
```

then visit the served HTML at http://localhost:8808.

YARD documentation is automatically published by rubygems site at each release.

### Maintainer tasks

ToDo:

* [ ] versioning and version dumping
* [ ] changelog/release
* [ ] publishing the gem
