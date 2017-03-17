Output = vector("numeric", length = length(rawData))
for (i in length(tableDF))
  {
  Output[i] = simQuery(rawData$Question_Text[i],rawData$Question_Text)
  }

print(Output)


