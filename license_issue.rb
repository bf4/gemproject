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

