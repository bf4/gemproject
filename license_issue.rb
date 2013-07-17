# see http://www.benjaminfleischer.com/2013/07/12/make-the-world-a-better-place-put-a-license-in-your-gemspec/
require 'yaml'
@downloads_yaml = 'zlatest_downloads.yml'
gems = YAML.load(File.read(@downloads_yaml))

STDOUT.sync = true

def github_repos_for_gems_without_licenses(gems)
  gems.
    select{|_,v| v['license'] == []}.
    map{|_,v|v['urls'].
        detect{|u| u =~ /\/github[^\/]+\/\w+\/\w+/} }.
    compact.map{|u| u.split('/')[3..4].join('/').sub('.git','') }
end
repos = github_repos_for_gems_without_licenses(gems)

@license_issues = 'license_issues.txt'
made_an_issue = File.readlines("./#{@license_issues}").map(&:strip)
unable_to_issue_issue = File.readlines("./failed_#{@license_issues}").map(&:strip)
already_processed =  made_an_issue | unable_to_issue_issue

def license_issues(repo, state = 'open')
  `ghi list -s#{state} -- #{repo} | egrep -i 'licence|license' >> /dev/null && echo 'has_issue'`
end
def has_no_license_issues?(repo)
  %w(open closed).all? do |state|
    has_issue = license_issues(repo, state)
    p [has_issue, repo, state]
    has_issue == ''
  end
end
def github_repos_without_license_issue(repos, already_processed)
  repos.reject{|repo| already_processed.include?(repo)}.select do |repo|
    has_no_license_issues?(repo)
  end
end
needs_issue = github_repos_without_license_issue(repos, already_processed)

def issue_message
  @message ||= begin
    subject = "License missing from gemspec"
    body = <<-BODY
Some companies [will only use gems with a certain license](https://github.com/rubygems/rubygems.org/issues/363#issuecomment-5079786).
The canonical and easy way to check is [via the gemspec](http://docs.rubygems.org/read/chapter/20#license)
via e.g.

    spec.license = 'MIT'
    # or
    spec.licenses = ['MIT', 'GPL-2']

There is even a [License Finder](https://github.com/pivotal/LicenseFinder) to help companies ensure all gems they use
meet their licensing needs. This tool depends on license information being available in the gemspec.
Including a license in your gemspec is a good practice, in any case.

If you need help choosing a [license](http://opensource.org/licenses), github has created a [license picker tool](http://choosealicense.com/)

How did I find you?

I'm using a script to collect stats on gems, originally looking for download data, but decided to collect licenses too,
and make issues for missing ones as a public service :)
https://gist.github.com/bf4/5952053#file-license_issue-rb-L13 So far it's going pretty well.
I've written a [blog post about it](http://www.benjaminfleischer.com/2013/07/12/make-the-world-a-better-place-put-a-license-in-your-gemspec/)
BODY
    [subject,body].join("\n\n")
  end
end
def create_issues_for_repos(needs_issue)
  needs_issue.each do |repo|
    p "Creating issue for #{repo}"
    `ghi create -m "#{issue_message}" -- #{repo} && echo "#{repo}" >> #{@license_issues} || echo '#{repo}' >> failed_#{@license_issues}`
  end
end
create_issues_for_repos(needs_issue)
