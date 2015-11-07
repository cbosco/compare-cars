## Quick start

    $ gem install bundler
    $ bundle install
    $ foreman start -f Procfile.dev
    
This will use shotgun and start a server at `http://localhost:9393/`

Alternatively you can use `thin` as heroku does by using the default Procfile

    $ foreman start
    
This will start a server at `http://localhost:5000/`


## Requirements

**ruby 1.9.3**  (see [RVM](https://rvm.io//))

