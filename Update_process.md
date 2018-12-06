
(TERMINAL)
1. checkout master - git pull
2. checkout new branch - git checkout -b dataUpdate[insert-date-here]   (format for date = 231218, aka. 23rd Dec 2018) 

(CONSOLE)
`source('./R/apiClient.R')`
`fetch_questions(show_progress = TRUE)`

(OPEN - TestQs.R script)
highlight and run the entire script (or `source(tests)) - this will flag up whether any conflicts occur with the existing database of PQs, if so our local database needs updating to match the API.

If no conflicts then move on to the next step.

If conflicts check the `nonMatchingQs` file to find out what the conflict if - if it appears like an error (introducing an NA, something nonsensical then ignore and move onto the next step). If it is due to a change in polictical party or other legitimate mismatch then you will need to:

1. Delete the `Data/archived_pqs`
2. Re-run `fetch_questions(show_progress = TRUE)` in the console

system("Rscript ./data_generators/DataCreator.R -e prod")

(TERMINAL)
git add Data/MoJwrittenPQs.csv
git add Data/archived_pqs.csv
git add Data/searchSpace.rda
git add Data/topDozenWordsPerMember.csv
git add Data/topDozenWordsPerTopic.csv

git commit -n -m "Data Update [insert date here (format = 23/12/18); x,xxx Questions"   (Where x,xxx is the number of questions now in the corpus)

git push origin dataUpdate[insert_date]

Run server.R and make sure it works!

If not go back and fix, redo the process and otherwise get it working (repush to same branch)

Go onto github and make a PR

Get someone to review and Schmo

Pull into master

Make a new release (follow the same versioning and format as the previous ones!)

DONE!

Remember to checkout master and pull before starting again the next time :)

