source 'https://rubygems.org'

ruby '1.9.3'
# prod
gem "sinatra"
gem "foreman"
gem "thin"

# app
gem "rest-client", "~> 1.6.7"

group :development, :test do
    # local
    gem "shotgun"

    # test
    gem "rack-test"			# rack/test
    gem "rspec"
    gem "ZenTest"
    # test db
    #gem "autotest-standalone"	# lightweight ZenTest
    gem "autotest-growl"	# autotest/growl
    gem "autotest-fsevent"	# autotest/fsevent
end
