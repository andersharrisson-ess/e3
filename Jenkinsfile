node('docker-ce') {
    // Clean workspace
    cleanWs()

    // Checkout E3 repo
    checkout scm

    sh 'echo "E3_EPICS_PATH:=/tmp" > CONFIG_BASE.local'
    sh 'echo "EPICS_BASE:=/tmp/base-3.15.5" > RELEASE.local'

    // Checkout base
    dir('e3-base') {
        git url: "https://github.com/icshwi/e3-base"
    }

    // Checkout require
    dir('e3-require') {
        git url: "https://github.com/icshwi/e3-require"
    }

    // Checkout modules
    def content = readFile 'configure/MODULES_COMMON'
    def modules = content.split('\n').findAll { !it.startsWith('#') }
    modules.each {
        dir(it) {
            git url: "https://github.com/icshwi/${it}"
        }
    }

    // Run build on Debian 9
    docker.build("debian9", "environments/debian/9").inside {
        // init base
        dir('e3-base') {
            sh 'make init'
            sh 'make env'
            sh 'make patch'
        }
        // init require
        dir('e3-require') {
            sh 'make init'
            sh 'make env'
        }
        // init modules
        modules.each {
            dir(it) {
                sh 'make init'
                sh 'make env'
                sh 'make patch'
            }
        }
        // build base
        dir('e3-base') {
            sh 'make build'
        }
        // build require
        dir('e3-require') {
            sh 'make build'
            sh 'make install'
        }
        // build modules
        modules.each {
            dir(it) {
                sh 'make build'
                sh 'make install'
            }
        }
    }
}
