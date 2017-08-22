# Data manipulation steps

##Introduction

This document runs through the steps in data extraction and manipulation, for QA purposes. It is accurate as of 22/8/17, and intended to provide summary as part of the Quality Assurance process for the internal release of the tool to the MoJ.

It is only a summary: those who want more detail should consult the data extraction and manipulation script itself, DataCreator.R.


##Phase 1: getting the data



##Phase 2: cleaning the data

We now follow a series of steps to clean the data. Some of these steps are standard in natural language processing, while many are specific to this data and this usage. The following table shows the steps in order.

| Step | Process                                          | Reason                                                                   |
| ---- | ------------------------------------------------ | ------------------------------------------------------------------------ |
| 1    | Swap occurrences of "High Down" with "Highdown". | Make sure HMP Highdown is not conflated with questions about legal highs |

