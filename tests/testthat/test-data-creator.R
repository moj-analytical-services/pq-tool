library(testthat)

context('nameCleaner')

test_that('does not reformat the names of peers', {
  peers <- c(
    'Lord John H. Smith',
    'Lady Jane H. Smith',
    'The John H. Smith',
    'Baroness Jane H. Smith',
    'Viscount John H. Smith'
  )
  for(peer in peers) {
    actual   <- nameCleaner(peer)
    expected <- peer
    expect_equal(actual, expected)
  }
})

test_that('otherwise, removes excess whitespace and formats: surname, firstname initials', {
  actual   <- nameCleaner('Mr  John  H.  Smith')
  expected <- 'Smith, John H.'
  expect_equal(actual, expected)
})

test_that('deals with some special cases and duplicated entries', {
  expect_equal(nameCleaner('Sir David Amess'), 'Amess, Sir David')
  expect_equal(nameCleaner('Sir Hugh Bayley'), 'Bayley, Sir Hugh')
  expect_equal(nameCleaner('Dr Roberta Blackman-Woods'), 'Blackman-Woods, Dr Roberta')
  expect_equal(nameCleaner('Nick de Bois'), 'de Bois, Nick')
  expect_equal(nameCleaner('Sir Simon Burns'),'Burns, Sir Simon')
  expect_equal(nameCleaner('Sir David Crausby'),'Crausby, Sir David')
  expect_equal(nameCleaner('Graham P Jones'), 'Jones, Graham')
  expect_equal(nameCleaner('Ian C. Lucas'), 'Lucas, Ian')
  expect_equal(nameCleaner('Grahame M. Morris'), 'Morris, Grahame')
  expect_equal(nameCleaner('Gloria De Piero'), 'De Piero, Gloria')
  expect_equal(nameCleaner('Sir Nicholas Soames'), 'Soames, Sir Nicholas')
})

context('cleanCorpus')

test_that('Cleans the corpus of various troublesome elements', {
  dirty_corpus <- readRDS('./examples/data/corpus.rda')
  actual       <- cleanCorpus(dirty_corpus)
  expected     <- readRDS('./examples/data/cleaned_corpus.rda')
  expect_equal(actual, expected)
})

context('summarise')

test_that('Summarises top 12 terms per cluster', {
  matrix    <- readRDS('./examples/data/matrix.rda')
  hierarchy <- readRDS('./examples/data/clustering_hierarchy.rda')
  questions <- read_csv('./examples/data/lsa_training_sample.csv')$Question_Text
  actual    <- summarise(type = 'cluster', 1, matrix, hierarchy, 12, questions, 100)
  expected  <- readRDS('./examples/data/cluster_one_summary.rda')
  expect_equal(actual, expected)
})

context('fromItoY')

test_that('Substitutes i for y, when it occurs at the end of a word', {
  expect_equal(fromItoY('endi'), 'endy')
  expect_equal(fromItoY('istart'), 'istart')
  expect_equal(fromItoY('middle'), 'middle')
})

context('normVec')

test_that('Returns the length of a vector',{
  vec      <- c(1,1)
  actual   <- signif(normVec(vec), digits = 3)
  expected <- 1.41
  expect_equal(actual, expected)
})

context('normalize')

test_that('normalises the lengths of a matrix to length 1', {
  matrix   <- readRDS('./examples/data/matrix.rda')
  actual   <- normalize(matrix)
  expected <- readRDS('./examples/data/normalised_matrix.rda')
  expect_equal(actual, expected)
})
