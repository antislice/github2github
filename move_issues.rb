# encoding:UTF-8
# !/usr/bin/env ruby
require 'OctoKit'
# require 'highline/import'

client = Octokit::Client.new(netrc: true)
client.login

if ARGV.empty?
  puts 'Usage: ruby move_issues.rb source-repo target-repo label-on-issues-to-move'
  exit 0
end

source_repo = ARGV.shift
target_repo = ARGV.shift
label = ARGV.shift

joblint_issues = Octokit.issues(source_repo, labels: label, state: 'open')
puts 'Issues to move'
joblint_issues.each do |issue|
  puts issue.title
end

puts 'Existing labels'
puts Octokit.labels(target_repo).map(&:name)

puts 'Existing milestones'
puts Octokit.milestones(source_repo).map(&:title)