require 'yaml'
@downloads_yaml = 'latest_downloads.yml'
gems = YAML.load(File.read(@downloads_yaml))

def github_repos_for_gems_without_licenses(gems)
  gems.select{|_,v| v['license'] == []}.map{|_,v|v['urls'].detect{|u| u =~ /github/} }.compact.map{|u| u.split('/')[-2..-1].join('/') }
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

def create_issues_for_repos(needs_issue)
  needs_issue.each do |repo|
    `ghi create -m "License missing from gemspec" -- #{repo} && echo "#{repo}" >> #{@license_issues}`
  end
end
create_issues_for_repos(needs_issue)

# Should probably add more info to the issue message about why.
# When I follow up in repos, I am writing something like
#
# Some companies will only use gems with a certain license.  The canonical and easy way to check is via the gemspec.  e.g. see https://github.com/pivotal/LicenseFinder It's a good practice, in any case.
#
# I actually generated this issue from the command-line by checking recently released gems.  see https://gist.github.com/bf4/5952053/raw/0c66dc8b2031952088ceeea2c5b816d98d7c0395/license_issue.rb
