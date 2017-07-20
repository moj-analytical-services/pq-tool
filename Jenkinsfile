#!groovy

pipeline {

  parameters {
    choice(
      name: 'IP_RESTRICTIONS',
      description: 'Whether the user needs to access the app from specific IPs',
      choices: ipRestrictions.choices,
    )

    booleanParam(
      name: 'AUTHENTICATION_REQUIRED',
      description: 'Determine if the app requires authentication.',
      defaultValue: true
    )
  }

  agent any

  stages {

    stage('Deploy application') {
      steps {
        deploy()
      }
    }

  }
}
