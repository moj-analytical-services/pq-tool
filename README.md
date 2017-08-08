[![Build Status](https://travis-ci.org/moj-analytical-services/PQTool.svg?branch=master)](https://travis-ci.org/moj-analytical-services/PQTool)

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

### Defaults
*Input file (questions)*
* "${SHINY_ROOT}/tests/testthat/examples/lsa_training_sample.csv"
* Override using `-i` or `--input_file`

*Output directory (where the new data files are saved)*
* "${SHINY_ROOT}/tests/testthat/examples/"
* Override using `-o` or `--output_dir`

*Number of clusters (k)*
* 100
* Override using `-k` or `--k_clusters`

### From the command line
1. With defaults
    ```
    Rscript DataCreator.R
    ```
2. With args
    ```
    Rscript DataCreator.R -i  my_input_file.csv -o my_destination_dir -k 1000
    ```
    ```
    for example, from the PQTool directory
    Rscript data_generators/DataCreator.R -i  Data/archived_pqs.csv -o Data -k 1000
    ```
  
### From an R console
1. With defaults
    ```
    system("Rscript DataCreator.R")
    ```
2. With args
    ```
    system("Rscript DataCreator.R -i  my_input_file.csv -o my_destination_dir -k 1000")
    ```
    ```
    for example, from the PQTool directory
    system("Rscript data_generators/DataCreator.R -i  Data/archived_pqs.csv -o Data -k 1000")
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
