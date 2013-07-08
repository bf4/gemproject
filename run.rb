require 'gems'
require 'yaml/store'
require 'time'

class GemDownloads
  def initialize(store = store)
    p store
    update(store)
  end
  # gems = Gems.gems
  # Gems.dependencies ['metric_fu']
  # TypeError: incompatible marshal file format (can't be read)
  # Gems.total_downloads 'metric_fu'
  #
  # ["name", "downloads", "version", "version_downloads", "platform", "authors", "info", "project_uri", "gem_uri", "homepage_uri", "wiki_uri", "documentation_uri", "mailing_list_uri", "source_code_uri", "bug_tracker_uri", "dependencies"]
  def my_gems
    @gems ||= Gems.gems # implicit is my credentials
  end
  #see Gems.search, yank, unyank, owners
  # .total_downlods, name, version
  # Gems.downloads name, version, [daterange] # number of downloads by day

  def gems
    my_gems.concat(extra_gems).
      reject {|gem| rejected_gems.include?(gem['name']) }
  end
  # ["authors", "built_at", "description", "downloads_count", "number", "summary", "platform", "prerelease", "licenses"]
  def gem_releases(gem_name)
    Gems.versions(gem_name)
  end

  def extra_gems
    %w(reek ruby_parser rails_best_practices flog flay cane churn turbulence).map do |gem_name|
      Gems.info(gem_name)
    end
  end

  def rejected_gems
    @rejected_gems ||= %w(bf4-metrical bf4-metric_fu bf4-yui-rails bf4-browsercms bf4-bcms_news)
  end

  def store(name = 'gem_metrics.yml')
    @store ||= YAML::Store.new(name)
  end

  def datetime
    p Time.now.utc.xmlschema
  end

  def update(store)
    timestamp = datetime
    gems.each do |gem|
      gem_name = gem['name']
      dependencies = gem['dependencies']
      info = gem['info']
      url = gem['homepage_uri'] || gem['source_code_uri'] || gem['project_uri']
      store.transaction do
        store[gem_name] ||= {}
        store[gem_name]['info'] = info
        store[gem_name]['url'] = url
        gem_releases(gem_name).each do |gem_release|
          version =  gem_release['number']
          count =       gem_release['downloads_count']
          build_date =  gem_release['built_at']
          store[gem_name][version] ||= {}
          store[gem_name][version]['build_date'] = build_date
          store[gem_name][version]['downloads'] ||= {}
          store[gem_name][version]['downloads'][count] = timestamp
        end
        store[gem_name]['dependencies'] = dependencies
      end
    end
  end
end
GemDownloads.new
