|Activity|Done (delete as appropriate)| Notes |
|---|---|---|
|**Code Structure**|||
|Clear logical separation of parameters, assumptions, data, and code. For R, use [this](https://github.com/jimhester/lintr), and use [Hadley’s Style Guide](http://r-pkgs.had.co.nz/style.html)|✅||
|Your code should (but not must) pass the relevant linter|❌||
|Appropriate use of abstractions like functions, packages, modules etc, which has been reviewed by language expert.  For R, you should use packages as fundamental units of code.|✅||
|If using a notebook (e.g. an R or Jupyter notebook) for your write up, functions are factored out to maintain narrative. For R, factor out code either into a `source()`ed `.R` file or a package|✅||
|**Reproducibility**|||
|If the output is a report, the write up is fully reproducible, or as close as possible.  For R, use `rmarkdown`|✅||
|**Development workflow**|||
|Code is version controlled using Git and checked into Github You can find a guide to using Git with R [here](http://happygitwithr.com/)|✅||
|The project is developed using [Git flow](https://guides.github.com/introduction/flow/). |✅||
|All code has been subject to code review.  This process has been managed through pull requests, and this evidenced in Github.  This should typically involve the reviewer pulling the code to their local machine, testing it, and leaving comments in the pull request.  |✅||
|**Documentation**|||
|You have added a description to your Github repository and tagged it with appropriate tags|✅||
|A README.md file exists in the repository, which contains standard fields |✅||
|Code is appropriately commented. [Comments are for explaining why something is needed, not how it works.](https://github.com/moj-analytical-services/our-coding-standards/blob/7e751164d577b521e7f62484a68ee1861f8ae4ac/they_are_users_too.md#L4)|✅||
|All non trivial functions are documented using the programming language's accepted standard. For R, use `roxygen2` to document your functions.|✅||
|**Unit testing**|||
|Unit tests exist that test the overall codebase, but not individual functions. In R, you should use the [testthat](https://github.com/hadley/testthat) package for unit testing.  You can find examples of how to do unit testing [here](https://github.com/ukgovdatascience/eesectors/tree/master/tests) and [here](https://github.com/RobinL/costmodelr/tree/master/tests)|✅||
|Unit tests exist at the function level, which test a range of parameters. |✅||
|Your unit testing has reached code coverage of at least 75%|❌||
|**Dependency Management**|||
|You dependencies are explicitly managed. For R, use packrat|✅||
|**Packages and versions**|||
|You have used the [sensible defaults](https://github.com/moj-analytical-services/our-coding-standards/blob/master/sensible_defaults.md), unless you have a good reason not to and have agreed this with your line manager|✅||
|**Language specific**|||
|Code Style: You must follow [Hadley’s style guide](http://adv-r.had.co.nz/Style.html)|✅||
|In R, you should generally use a [functional programming style.](http://adv-r.had.co.nz/Functional-programming.html)|✅||