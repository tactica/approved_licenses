# Pre-approved Licenses Repository

This repository serves as a centralized collection of software licenses approved for new projects, ensuring compliance with organizational policies regarding commercial use, modification, distribution, and public source code disclosure. It aims to maintain consistency across projects and simplify the license selection process.

## Purpose

The primary goal of this repository is to provide a curated list of licenses that are deemed suitable for our projects, prioritizing permissiveness and commercial viability. This list is especially useful for developers and legal teams to quickly identify licenses that meet our criteria without navigating the complexities of various license terms and conditions.

## Dependencies

To use the scripts and tools provided in this repository, ensure you have the following installed:

* **Ruby**: Required for the [license_finder](https://github.com/pivotal/LicenseFinder) gem.
* **curl**: Used for downloading the list of approved licenses.
* **bash**: Necessary for executing the script.

### Installation Instructions

* **Ruby**: Visit the [official Ruby documentation page](https://www.ruby-lang.org/en/documentation/installation) and follow the instructions for your operating system.
* **curl**: Most UNIX-like operating systems come with curl pre-installed. If you need to install it, please refer to the curl download page.
* **bash**: Typically pre-installed on UNIX-like systems. Windows users can use Git Bash, WSL, or Cygwin.

## Usage

If your project has a `Gemfile`,  `license_finder` should be included in your bundle:

```ruby
# Used to find licenses for project dependencies.
gem 'license_finder', require: false
```

Use this command at the root of your project on your local machine or within a CI pipeline:

```bash
curl -sSL https://raw.githubusercontent.com/tactica/approved_licenses/master/script.sh | bash
```

## Troubleshooting

If you encounter the error `cannot load such file -- racc/parser.rb (LoadError)` when using bundler, you need to add `racc` to your `Gemfile`:

```ruby
gem 'racc', require: false # dependency of license_finder
```

## Contribution Guidelines

Contributions to the list of pre-approved licenses are welcome. However, they must undergo a thorough review process to ensure that they meet our criteria for permissiveness and commercial use. Please submit a pull request with your proposed changes and a detailed justification for the inclusion of the new license.