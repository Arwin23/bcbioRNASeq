#!/bin/sh

# Render R Markdown templates
# Lorena Pantano, Michael Steinbaugh

setup_git() {
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "Travis CI"
}

commit_website_files() {
    git fetch origin gh-pages
    git checkout gh-pages
    git pull
    cp report/*.html .
    git add *.html
    git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
    git remote add origin-pages https://${GITHUB_TOKE}@github.com/bcbio/bcbio_rnaseq_output_example.git > /dev/null 2>&1
    git push --force --quiet --set-upstream origin-pages gh-pages
}

# Only render on Linux container
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    pwd
    cd ..
    git clone https://github.com/bcbio/bcbio_rnaseq_output_example.git
    cd bcbio_rnaseq_output_example
    Rscript -e 'devtools::install_local("../bcbioRNASeq")'
    Rscript -e 'testthat::test_file("test_reports.R")'
    cd report
    mv de.html de-${TRAVIS_BRANCH}.html
    mv qc.html qc-${TRAVIS_BRANCH}.html
    mv fa.html fa-${TRAVIS_BRANCH}.html
    cd ..

    setup_git
    commit_website_files
    upload_files
fi
