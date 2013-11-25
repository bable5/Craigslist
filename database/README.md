Django module to present the data in a database.
====

#### Enviroment Setup

This module use pip and virtualenv to manage the dependencies.

Run

    $> sudo apt-get install python-pip

to install pip.

Run

    $> sudo pip install virtualenv
    $> sudo pip install virtualenvwrapper

to install virtualenv and a set of helper/wrapper scripts.

Add the lines:

    $> export WORKON_HOME=~/.Envs
    $> mkdir -p $WORKON_HOME
    $> source /usr/local/bin/virtualenvwrapper.sh

to your <code>~/.bashrc</code> or <code>~/.bash_aliases</code> file.
Open a new terminal or source your <code>~/.bashrc</code> to pick up the
environment changes.

Create a new virtual environment for the project with

    $> mkvirtualenv craigslist

Activite with the virtual environment with:

    $> workon craigslist

Install depenedencies with:

    $> pip install -r django/requirements.txt

#### Setup the django app
Make sure you have activated the virtual environment. Running

    $> cd django
    $> python manage.py syncdb

will create the database.

Import new personal ads csv data with:

    $> python manage.py load_csv -f path/to/file

Run the server:

    $> python manage.py runserver

By default the server will be accessible to the localhost @ 127.0.0.1:8000

