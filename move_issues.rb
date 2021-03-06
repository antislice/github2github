# encoding:UTF-8
# !/usr/bin/env ruby
require 'OctoKit'
require 'highline/import'
require 'netrc'
require 'optparse'

options = {}

ARGV << '-h' if ARGV.empty?

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby move_issues.rb source-repo target-repo [label-on-issues-to-move]'

  opts.on('--leave-open', 'Leave the source-repo issues open') do |lo|
    options[:leave_open] = lo
  end
end.parse!

def maybe_add_labels_to_repo(issue_labels, repo, existing_labels)
  return if issue_labels.nil?
  labels_to_add = issue_labels.select { |l| !existing_labels.include?(l.name) }
  labels_to_add.each do |l|
    puts "Adding label '#{l.name}'"
    @client.add_label(repo, l.name, l.color)
  end
  labels_to_add.map(&:name)
end

def maybe_add_milestone_to_repo(source_milestone, repo, existing_milestones)
  return if source_milestone.nil?
  milestone = existing_milestones.find { |m| m.title.eql? source_milestone.title }
  if milestone.nil?
    puts "Adding milestone '#{source_milestone.title}'"
    milestone = @client.create_milestone(repo, source_milestone.title,
                                         description: source_milestone.description,
                                         due_on: source_milestone.due_on)
  end
  milestone
end

def maybe_assign_issue(new_issue_number, repo, assignee)
  if @client.check_assignee(repo, assignee)
    @client.update_issue(repo, new_issue_number, assignee: assignee)
  else
    @client.add_comment(repo, new_issue_number, "Attempted to assign issue to @#{assignee} but they're not assignable in this repo")
  end
end

def get_input(prompt = 'Enter >', show = true)
  ask(prompt) { |q| q.echo = show }
end

if Netrc.read['api.github.com'].nil?
  user = get_input('Enter Username > ')
  password = get_input('Enter Password > ', '*')
  @client = Octokit::Client.new \
    login: user,
    password: password
else
  @client = Octokit::Client.new(netrc: true)
end
@client.login

source_repo = ARGV.shift
target_repo = ARGV.shift
label = ARGV.shift

existing_labels = @client.labels(target_repo).map(&:name)
existing_milestones = @client.milestones(target_repo)

source_issues = @client.issues(source_repo, labels: label, state: 'open')

if source_issues.empty?
  puts "Nothing found in #{source_repo} for '#{label}'"
  exit 0
end

source_issues.each do |issue|
  puts "Moving issue #{issue.title} (##{issue.number})"

  new_issue_body = '' << issue.body << "\n\nThis issue originally created by @#{issue.user.login} as #{source_repo}##{issue.number}."

  # remove the search label from the labels to move
  issue.labels.select! { |l| !l.name.eql? label }
  existing_labels |= maybe_add_labels_to_repo(issue.labels, target_repo, existing_labels)
  # append to existing milestones, but get back the whole thing because we need the id later
  milestone = maybe_add_milestone_to_repo(issue.milestone, target_repo, existing_milestones)
  existing_milestones << milestone unless milestone.nil?

  new_issue = @client.create_issue(target_repo, issue.title, new_issue_body,
                                   labels: issue.labels.map(&:name).join(','))
  @client.update_issue(target_repo, new_issue.number, milestone: milestone.number) unless milestone.nil?
  maybe_assign_issue(new_issue.number, target_repo, issue.assignee.login) unless issue.assignee.nil?

  if issue.comments > 0
    comments = @client.issue_comments(source_repo, issue.number)
    comments.each do |source_comment|
      boilerplate = "ORIGINAL COMMENT BY @#{source_comment.user.login} ([here](#{source_comment.html_url}))\n\n"
      @client.add_comment(target_repo, new_issue.number, boilerplate << source_comment.body)
    end
  end

  @client.add_comment(source_repo, issue.number, "This issue was moved to #{target_repo}##{new_issue.number}")
  @client.close_issue(source_repo, issue.number) unless options[:leave_open]
end

puts "All done! #{source_issues.count} issues moved from #{source_repo} to #{target_repo}."
