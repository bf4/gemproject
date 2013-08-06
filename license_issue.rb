# see http://www.benjaminfleischer.com/2013/07/12/make-the-world-a-better-place-put-a-license-in-your-gemspec/
require 'yaml'
@downloads_yaml = 'zlatest_downloads.yml'
gems = YAML.load(File.read(@downloads_yaml))
STDOUT.sync = true

def get_license_stats(gems)
  @licenses = {}
  gems.map{|_,v|v['license']}.reject{|l|l == [] || l.nil? || l == "" || l == ['']}.each do |license|
    Array(license).each do |l|
      @licenses[l] ||= 0
      @licenses[l] += 1
    end
  end
  "count,license\n" <<
    @licenses.sort {|a,b| b[0].downcase <=> a[0].downcase}.map{|l,c| "#{c},#{l}\n"}.join
end
if ARGV[0] == 'license_stats'
  File.open('license_usage.csv', 'w') do |file|
    file.write(get_license_stats(gems))
  end
  exit
end
# @return Array<username/projectname>
def github_repos_for_gems_without_licenses(gems)
  gems.
    select{|_,v| v['license'] == []}.
    map{|_,v|v['urls'].
        detect{|u| u =~ /\/github[^\/]+\/\w+\/\w+/} }.
    compact.map{|u| u.split('/')[3..4].join('/').sub('.git','') }.uniq
end
username_blacklist = File.readlines('./user_blacklist.txt').map{|blacklist| /#{blacklist.strip}/io }
repos = github_repos_for_gems_without_licenses(gems).
          reject{|repo|
             username_blacklist.any?{|blacklist|
               blacklisted = repo.split('/')[0] =~ blacklist
               puts "Rejecting #{repo} due to blacklist #{blacklist}" if blacklisted
               blacklisted
             }
           }; nil

@license_issues = 'license_issues.txt'
made_an_issue = File.readlines("./#{@license_issues}").map(&:strip)
unable_to_issue_issue = File.readlines("./failed_#{@license_issues}").map(&:strip)
existing_issue  = File.readlines("./existing_#{@license_issues}").map(&:strip)
already_processed =  made_an_issue | unable_to_issue_issue | existing_issue

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
    has_no_license_issues?(repo) || (`echo '#{repo}' >> existing_#{@license_issues}` && false)
  end
end
needs_issue = github_repos_without_license_issue(repos, already_processed)

def issue_message
  @message ||= begin
    subject = "License missing from gemspec"
    body = <<-BODY
RubyGems.org doesn't report a license for your gem.  This is because it is not specified in the [gemspec](http:t/docs.rubygems.org/read/chapter/20#license) of your last release.

via e.g.

    spec.license = 'MIT'
    # or
    spec.licenses = ['MIT', 'GPL-2']

Including a license in your gemspec is an easy way for rubygems.org and other tools to check how your gem is licensed.  As you can image, scanning your repository for a LICENSE file or parsing the README, and then attempting to identify the license or licenses is much more difficult and more error prone. So, even for projects that already specify a license, including a license in your gemspec is a good practice. See, for example, how [rubygems.org uses the gemspec to  display the rails gem license](https://rubygems.org/gems/rails).

There is even a [License Finder gem](https://github.com/pivotal/LicenseFinder) to help companies/individuals ensure all gems they use meet their licensing needs. This tool depends on license information being available in the gemspec.  This is an important enough issue that *even Bundler now generates gems with a default 'MIT' license*.

I hope you'll consider specifying a license in your gemspec. If not, please just close the issue with a nice message. In either case, I'll follow up. Thanks for your time!

Appendix:

If you need help choosing a [license](http://opensource.org/licenses) (sorry, I haven't checked your readme or looked for a license file), GitHub has created a [license picker tool](http://choosealicense.com/).  Code without a license specified defaults to 'All rights reserved'-- denying others all rights to use of the code.
Here's a [list of the license names I've found and their frequencies](https://github.com/bf4/gemproject/blob/master/license_usage.csv)

p.s. In case you're wondering how I found you and why I made this issue, it's because I'm collecting stats on gems (I was originally looking for download data) and decided to collect license metadata,too, and [make issues for gemspecs not specifying a license as a public service :)](https://github.com/bf4/gemproject/issues/1). See the previous link or my [blog post about this project for more information](http://www.benjaminfleischer.com/2013/07/12/make-the-world-a-better-place-put-a-license-in-your-gemspec/).
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
