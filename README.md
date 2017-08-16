[![Build Status](https://travis-ci.org/moj-analytical-services/PQTool.svg?branch=master)](https://travis-ci.org/moj-analytical-services/pq-tool)

# PQ Tool
## Introduction
This is a prototype tool for analysing and comparing written Parliamentary Questions for answer by the Ministry of Justice. Questions have been scraped from the parliamentary website (http://www.parliament.uk/business/publications/written-questions-answers-statements/written-questions-answers/).

The tool allows the user to input a new question, or a key phrase, and produces a score and ranking of similarity between the input and the bank of past PQs. It also groups questions under 'topics' based on similar subject matter.

The tool is written in R and is based on a technique called Latent Semantic Analysis. For more information, or to provide any feedback/ideas please send an email to samuel.tazzyman@justice.gsi.gov.uk

To access the deployed tool go to https://mojproducts.shinyapps.io/pqtool/
## Running DataCreator.R
### This script will create four data files
1. The search space.
2. A new csv of questions with cluster assignments.
3. A new csv of the 12 most significant terms in each cluster.
4. A new csv of the 12 most significant terms for each MP/Peer.

### Arguments

Four arguments can be passed to the DataCreator.R script.  The environment flag `-e` can be used as a shortcut to set sensible values for input (`-i`), output (`-o`) and K (`-k`), for the two most common use cases:
1. Quickly generating a small data set for testing purposes and avoid overwriting production data.
2. Generating the full data set for use in production, overwriting previously generated producttion data

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
    ```
3. With specific args
    ```
    # From the command line
    Rscript ./data_generators/DataCreator.R -i  Data/archived_pqs.csv -o Data -k 1000
    
    # From an R console
    system("Rscript ./data_generators/DataCreator.R -i  Data/archived_pqs.csv -o Data -k 1000")
    ```

## Running the tool

### To run the tool:
1) Clone the Repo
2) Point your working directory to the 'PQTool_master' folder 
3) Open one of global.R, server.R or ui.R in RStudio then hit 'Run App'.

## Testing

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
