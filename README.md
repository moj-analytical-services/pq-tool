[![Build Status](https://travis-ci.org/moj-analytical-services/PQTool.svg?branch=master)](https://travis-ci.org/moj-analytical-services/pq-tool)

# PQ Tool
## Introduction
This is a prototype tool for analysing and comparing written Parliamentary Questions for answer by the Ministry of Justice. Questions have been taken from the API provided by Parliament (accessed via http://www.data.parliament.uk/).

The tool allows the user to input a new question, or a key phrase, and produces a score and ranking of similarity between the input and the bank of past PQs. It also groups questions under 'topics' based on similar subject matter.

The tool is written in R and is based on a technique called Latent Semantic Analysis. For more information, or to provide any feedback/ideas please send an email to samuel.tazzyman@justice.gsi.gov.uk

To access the deployed tool within the Ministry of Justice go to https://pq-tool.apps.alpha.mojanalytics.xyz/. If you are not from the MoJ, you can fork and run locally.

## Some variables are defined in .Rprofile

Variables in block capitals are defined in .Rprofile because they're used in serveral different R files.  This should load automatically whenever you start a new R session from the comand line.  If you make changes to .Rprofile, remember that you will either need to open a new R session to load the changes or do `source('./Rprofile')`

## Generating and updating the archive of PQs
### In an R console
```
source('./R/apiClient.R')
# Without feedback
fetch_questions()
# With feedback
fetch_questions(show_progress=TRUE)
```

- When this function is called for the first time, and no archive exists, it will create archived_pqs.csv in the Data directory and download all answered PQs, that were posed to the MoJ, from http://lda.data.parliament.uk/answeredquestions. This takes about 8.5 minutes on a 2016 MacBook Pro.

- When an archive already exists, the function will update archived_pqs.csv by appending newly answered questions (downloaded from the same endpoint).

- Variables in BLOCK_CAPITALS are defined in .Rprofile

## Generating the data
There are three files that create the data, within the data_generators folder.
1. MoJScraper.R
Previously we scraped the parliament website to get our data, but now we use the API, so this file is no longer used, but is included for completeness.
2. DataCreator.R
This does the work of getting and manipulating the data. See below for details of how to run it.
3. MPClustering.R
This is a work in progress and is not yet used in the tool.

## Running DataCreator.R
### This script will create four data files
1. The search space.
2. A new csv of questions with cluster assignments.
3. A new csv of the 12 most significant terms in each cluster.
4. A new csv of the 12 most significant terms for each MP/Peer.

### Arguments

Four arguments can be passed to the DataCreator.R script.  The environment flag `-e` can be used as a shortcut to set sensible values for input (`-i`), output (`-o`) and K (`-k`), for the two most common use cases:
1. Quickly generating a small data set for testing purposes and avoid overwriting production data.
2. Generating the full data set for use in production, overwriting previously generated production data

Input, output and K can also be set individually, but if environment is also set, they will be overridden.

*Environment (test/prod)*
* A shortcut to set values for the other three arguments in one go.
* Use `-e test` OR `-e prod`

*Input file (questions)*
* When `-e test`
    * "${SHINY_ROOT}/tests/testthat/examples/lsa_training_sample.csv"
* When `-e prod`
    * "${SHINY_ROOT}/Data/archived_pqs.csv"
* Set to something else using `-i` or `--input_file`

*Output directory (where the new data files are saved)*
* When `-e test`
    * "${SHINY_ROOT}/tests/testthat/examples/"
* When `-e prod`
    * "${SHINY_ROOT}/Data/"
* Set to something else using `-o` or `--output_dir`

*Number of dimensions for rank-reduced space (x)*
* When `-e test`
    * 100
* When `-e prod`
    * 2000 
* Set to something else using `-x` or `--x_dims`

*Number of clusters (k)*
* When `-e test`
    * 100
* When `-e prod`
    * 1000 
* Set to something else using `-k` or `--k_clusters`

### Examples
1. Defaulting to `-e test`
    ```
    # From the command line
    Rscript ./data_generators/DataCreator.R
    
    # From an R console
    system("Rscript ./data_generators/DataCreator.R")    
    ```
2. For production
    ```
    # From the command line
    Rscript ./data_generators/DataCreator.R -e prod
    
    # From an R console
    system("Rscript ./data_generators/DataCreator.R -e prod")

    This takes about 11 minutes on a 2016 Macbook Pro.
    ```
3. With specific args
    ```
    # From the command line
    Rscript ./data_generators/DataCreator.R -i  Data/archived_pqs.csv -o Data -k 1000 -x 2000
    
    # From an R console
    system("Rscript ./data_generators/DataCreator.R -i  Data/archived_pqs.csv -o Data -k 1000 -x 2000")
    ```

## Running the tool

### To run the tool:
1) Clone the Repo
2) Point your working directory to the 'PQTool_master' folder 
3) Open one of global.R, server.R or ui.R in RStudio then hit 'Run App'.

## Testing

Please make sure you run all tests, and that they pass, before making a pull request.  This is especially important because some of the tests in test-tour.R will not run on Travis.  This is, hopefully, temporary, whilst we get to the bottom of why those tests do not pass on Travis (whilst they do pass locally).

### To run the tests you will need [RSelenium][1] and [geckodriver][2]

```
brew install selenium-server-standalone
brew install geckodriver
```

### Then you'll need to start the Selenium server in a new terminal

```
java -jar -Dwebdriver.gecko.driver=/<path_to_gecko>/geckodriver /<path_to_selenium>/selenium-server-standalone-3.3.1.jar
```

### And start your app (note that the test suite is pointed at port 8888)
```
runApp('/path_to_app/', port=8888)
```

### Now you can actually run the tests (from inside an R session)

```
devtools::test()
```

[1]: https://cran.r-project.org/web/packages/RSelenium/vignettes/RSelenium-basics.html
[2]: https://github.com/mozilla/geckodriver/

## Deploying within MoJ

To deploy, you will need access to the Jenkins console.  Once there, find the name of this app (pq-tool), select the branch that you want to deploy then go to 'build with parameters'.  If you're not sure what parameters to use, have a look at previous builds and see what parameters were used there.

At the moment, using this pipeline, the only way for us to deploy to more than one env, is to have more than one repo.  We have created a second repo called pq-tool-staging.  This is new repo exclusively for the purpose of testing branches and all branches pushed there should be considered disposable.  You should also clean up after yourself and delete branches (from that repo) that are no longer needed for testing.

### To add this as a remote repo
```
git remote add staging git@github.com:moj-analytical-services/pq-tool-staging.git
```

### Then you can push to that repo (and deploy from the Jenkins console using the pq-tool-staging job)
```
git push staging branch-to-test
```
## Deploying for External access

A seperate repo (pq-tool-external) has been created to allow access outside of the MoJ to selected people - usually from other government departments.

### To add this as a remote repo
```
git remote add staging git@github.com:moj-analytical-services/pq-tool-external.git
```

### Then you can push to that repo (and deploy from the Jenkins console using the pq-tool-external job)
```
git push external branch-to-deploy
