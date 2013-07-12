require 'yaml'
@downloads_yaml = 'zlatest_downloads.yml'
gems = YAML.load(File.read(@downloads_yaml))

STDOUT.sync = true

def github_repos_for_gems_without_licenses(gems)
  gems.select{|_,v| v['license'] == []}.map{|_,v|v['urls'].detect{|u| u =~ /github/} }.compact.map{|u| p u; p u.split('/')[-2..-1].join('/') }
end
repos = github_repos_for_gems_without_licenses(gems)

@license_issues = 'license_issues.txt'
already_processed = File.readlines("./#{@license_issues}").map(&:strip)

def github_repos_without_license_issue(repos, already_processed)
  repos.reject{|repo| already_processed.include?(repo)}.select do |repo|
    has_issue = `ghi list -- #{repo} | grep -i 'license' > /dev/null && echo 'has issue'`
    p [has_issue, repo]
    has_issue == ''
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

How did I find you?

I'm using a script to collect stats on gems, originally looking for download data, but decided to collect licenses too,
and make issues for missing ones as a public service :)
https://gist.github.com/bf4/5952053#file-license_issue-rb-L13 So far it's going pretty well
BODY
    [subject,body].join("\n\n")
  end
end
def create_issues_for_repos(needs_issue)
  needs_issue.each do |repo|
    p "Creating issue for #{repo}"
    `ghi create -m "#{issue_message}" -- #{repo} && echo "#{repo}" >> #{@license_issues}`
  end
end
create_issues_for_repos(needs_issue)
