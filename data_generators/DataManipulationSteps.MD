# Data manipulation steps

## Introduction

This document runs through the steps in data extraction and manipulation, for QA purposes. It is accurate as of 22/8/17, and intended to provide summary as part of the Quality Assurance process for the internal release of the tool to the MoJ.

It is only a summary: those who want more detail should consult the data extraction and manipulation script itself, DataCreator.R.


## Phase 1: getting the data



## Phase 2: cleaning the data

We now follow a series of steps to clean the data. Some of these steps are standard in natural language processing, while many are specific to this data and this usage. The following table shows the steps in order.

| Step | Process                                          | Reason                                                                                                                |
| ---- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| 1    | Swap occurrences of "High Down" with "Highdown"  | So HMP Highdown is not conflated with questions about legal highs                                                     |
| 2    | Replace hyphens with spaces                      | So "Northern Ireland-related" doesn't become "Northern Irelandrelated" when we remove punctuation later               |
| 3    | Take out html tags for italics                   | Ensures consistency with the names of companies                                                                       |
| 4    | Take out all non-alphanumeric symbols            | Standard practice                                                                                                     |
| 5    | Remove word "Justice"                            | Prevent references to "Secretary of State for Justice" becoming conflated with other uses of "justice"                |
| 6    | Make all text lower case                         | Standard practice                                                                                                     |
| 7    | Swap "re off" for "reoff"                        | Make sure variant spellings of reoffending are considered to be the same after step 2's hyphen swap                   |
| 8    | Swap "anti " for "anti"                          | Make sure variant spellings, e.g. "anti-semitic"/"antisemitic" are considered to be the same                          |
| 9    | Swap "cross exam" for "crossexam"                | Make sure variant spellings, e.g. "cross-examination"/"crossexamination" are considered to be the same                |
| 10   | Swap "socio eco" for "socioeco"                  | Make sure variant spellings of socio-economics are considered to be the same                                          |
| 11   | Swap "inter " for "inter"                        | So we don't get clusters based around the prefix "inter"                                                              |
| 12   | Swap "rehabilitaiton" for "rehabilitation"       | Correct one-off typo in a question                                                                                    |
| 13   | Swap "organisaitons" for "organisations"         | Correct one-off typo in a question                                                                                    |
| 14   | Swap "directive" and "directives" for "drctv"    | Prevent "directive", "directly", and "direction" all becoming identical following stemming step 21                    |
| 15   | Swap "direction" and "directions" for "drctn"    | Prevent "directive", "directly", and "direction" all becoming identical following stemming step 21                    |
| 16   | Swap "internal" for "intrnl"                     | Prevent "internal" and "international" becoming identical following stemming step 21                                  |
| 17   | Swap "probation" for "probatn"                   | Prevent "probation" and "probate" becoming identical following stemming step 21                                       |
| 18   | Swap "network rail" for "networkrail"            | So Network Rail is seen as distinct from other types of networks                                                      |
| 19   | Remove bespoke list of stopwords                 | Remove unhelpful common words and parliamentary phrases - see .Rprofile file for complete list of removed words       |
| 20   | Remove excess white space                        | Clean up                                                                                                              |
| 21   | Word stemming                                    | Reduce words to their stems using standard algorithm to make sure tenses and cases don't obscure similar meanings     |

Having done this processing we now have a list of cleaned up and boiled down PQs which we turn into a term-document matrix. Our weighting scheme is as follows:

 * Boolean term frequency score: Given a term *t* and a document *d*, score 1 if *t* is in *d* and 0 otherwise.
 * Normalisation: since some documents are longer than others (especially once we remove stopwords and so on) we need to make sure that they don't get scored highly based on their length alone. So after the above step we normalise so that each column vector (each document) has length 1.
 * Inverse document frequency score: Given a term *t* which occurs in *M* of *N* documents, score *log*_2_(*N*/*M*), i.e. score higher for terms found in a smaller proportion of documents. Multiply this score by the previous and you've got your final score.

This gives us our term-document matrix (TDM).

## Phase 3: The LSA

We now do a Latent Semantic Analysis, using the R library tm. This will allow us to use a rank-reduced space.
