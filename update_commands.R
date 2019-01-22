library(sendmailR)

source('./R/apiClient.R')
fetch_questions(show_progress = TRUE)
source('./tests/TestQs.R')
	if error:
		sender <- "SENDER@gmail.com"
		recipients <- c("RECIPIENT@gmail.com")
		send.mail(from = sender,
			  to = recipients,
			  subject = "Subject of the email",
			  body = "Body of the email",
			  smtp = list(host.name = "smtp.gmail.com", port = 465, 
				      user.name = "YOURUSERNAME@gmail.com",            
				      passwd = "YOURPASSWORD", ssl = TRUE),
			  authenticate = TRUE,
			  send = TRUE)
system("Rscript ./data_generators/DataCreator.R -e prod")
