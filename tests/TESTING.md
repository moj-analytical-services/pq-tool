## Feature / integration tests

### Within test-basic.R
We perform two high level tests which ensure:
1. The application is running
2. There are no errors on the landing page

Any bugs which fundamentally break the application will be caught here.


### Within test-search.R
We perfor one test that ensures:
1. The search field is present
2. A query string can be entered and submitted
3. Some results are returned and displayed in a table
4. The table has 10 rows

Any bugs which break the search function, prevent the table from being displayed, or cause the table to drastically change, will be caught here.


## Unit tests

### Within test-api-client.R
We perform 20 unit tests to ensure:
1. API calls are formatted correctly when an archive of PQs *is not* already present
2. API calls are formatted correctly when an archive of PQs *is* already present
3. The most important functions all work as expected
4. Data returned by the API is handled correctly

Within these tests we do not actually make real calls to the API.  This is to ensure our tests are not dependent on an internet connection.  Also, we *should not* need to test the API itself, since that is tested and maintained by a third party.  We only need, and only do, test that the messages we send to the API endpoint are correct and that we handle responses from the API (also mocked) correctly.  We have been assured by the team who maintain the API that it will not change in the foreseeable future and have alerted them as to our dependence on their service.

### Within test-functions.R
We perform unit tests on all non-debugging functions within the Functions.R file. We make sure:
* The nameCleaner functions does not reformat peers' names
* it reformats 'standard' MP names correctly
* it deals with a raft of special cases appropriately
* The cleanCorpus function produces a cleaned corpus to match one in the archive (note we do not generate this live)
* The summary function matches output in the archive
* The fromItoY function cleans up words appropriately
* The normalize function correctly normalises the columns of a matrix
* The queryVec function gives back a vector of numbers representing the indices of the search terms in an archived vocabulary
* The familyName function gives back family names only
* The firstName function gives back first names only
* the urlName function gives back names for urls including in various edge cases


## Continuous integration

We use Travis to run all our of the above tests on each branch and pull request.  To achieve this, Travis builds our application remotely on AWS and is, therefore, a close approximation of the production environment (the Analytics Platform, also on AWS).  We do not, and cannot, merge new code into the master branch, unless the tests performed by Travis all pass.  This means, the codebase on the master branch, which we deploy to the Analytics Platform, is protected from breaking changes.
