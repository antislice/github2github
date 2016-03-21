# encoding:UTF-8
# !/usr/bin/env ruby
require 'OctoKit'
# require 'highline/import'

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

def maybe_assign_issue(new_issue, repo, assignee)
  # => check if assignee "exists" in this repo
  # => if they do, assign to them
  # => if not, add comment about attempting to assign them
  # @client.update_issue(target_repo, new_issue.number, assignee: issue.assignee.login)
end

@client = Octokit::Client.new(netrc: true)
@client.user.login

if ARGV.empty?
  puts 'Usage: ruby move_issues.rb source-repo target-repo label-on-issues-to-move'
  exit 0
end

source_repo = ARGV.shift
target_repo = ARGV.shift
label = ARGV.shift

existing_labels = Octokit.labels(target_repo).map(&:name)
existing_milestones = Octokit.milestones(target_repo)

source_issues = Octokit.issues(source_repo, labels: label, state: 'open')
puts 'Issues to move'
source_issues.each do |issue|
  puts issue.title

  new_issue_body = issue.body << "\n\nThis issue originally created by [#{issue.user.login}](#{issue.user.url}) as #{issue.url}."

  # union w/ other existing labels
  existing_labels |= maybe_add_labels_to_repo(issue.labels, target_repo, existing_labels)
  # append to existing milestones, but get back the whole thing because we need the id later
  milestone = maybe_add_milestone_to_repo(issue.milestone, target_repo, existing_milestones)
  existing_milestones << milestone.title unless milestone.nil?

  new_issue = @client.create_issue(target_repo, issue.title, new_issue_body,
                                   labels: issue.labels.map(&:name).join(','))
  @client.update_issue(target_repo, new_issue.number, new_issue.title, milestone: milestone.number) unless milestone.nil?
  # assign issue
  maybe_assign_issue(new_issue, target_repo, issue.assignee.login) unless issue.assignee.nil?
end

# for each issue:
# add issue to target_repo
# => add line at the bottom of the issue description about who originally filed it in what repo
# => add labels
# => => if any of the labels don't exist, add them
# => same for milestones
# => add comments (do I need to edit them to indicate who originally made them? probably.)
# => close first issue
# remove "search label" from target repo
