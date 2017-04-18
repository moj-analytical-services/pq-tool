[![Run Status](https://api.shippable.com/projects/58d10e96665a9306000199bb/badge?branch=master)](https://app.shippable.com/github/moj-analytical-services/PQTool)

# PQ Tool

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
