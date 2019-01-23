# See this page for more details on what these commands are doing: https://github.com/moj-analytical-services/pq-tool/blob/add_instructions/Update_process.md

source('./R/apiClient.R')
fetch_questions(show_progress = TRUE)
source('./tests/TestQs.R')
system('Rscript ./data_generators/DataCreator.R -e prod')
