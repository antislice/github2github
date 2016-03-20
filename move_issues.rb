#encoding:UTF-8
#!/usr/bin/env ruby
require 'OctoKit'
#require 'highline/import'


client = Octokit::Client.new(netrc: true)
client.login

joblint_issues = Octokit.issues('codeforamerica/nola-2016-fellows', labels: 'job-posting')
joblint_issues.each do |issue| 
  puts issue.title
end