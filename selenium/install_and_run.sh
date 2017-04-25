echo "*** Installing Seleniumn"
wget http://selenium-release.storage.googleapis.com/3.4/selenium-server-standalone-3.4.0.jar

echo "*** Installing Geckodriver"
wget https://github.com/mozilla/geckodriver/releases/download/v0.16.1/geckodriver-v0.16.1-linux64.tar.gz

echo "*** Extracting and preparing Geckodriver"
tar -xvzf geckodriver-v0.16.1-linux64.tar.gz
chmod +x geckodriver
export PATH=$PATH:./geckodriver

echo "*** Starting up Selenium server"
DISPLAY=:1 xvfb-run java -jar ./selenium-server-standalone-3.4.0.jar
