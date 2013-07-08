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
  def my_gems
    gems ||= Gems.gems
  end

  # ["name", "downloads", "version", "version_downloads", "platform", "authors", "info", "project_uri", "gem_uri", "homepage_uri", "wiki_uri", "documentation_uri", "mailing_list_uri", "source_code_uri", "bug_tracker_uri", "dependencies"]
  def my_gems_by(key)
    my_gems.map {|gem| gem[key.to_s] }
  end
  def gem_releases(gem_name)
    Gems.versions(gem_name)
  end
  # ["authors", "built_at", "description", "downloads_count", "number", "summary", "platform", "prerelease", "licenses"]
  def gem_release_attributes(gem_release, args)
    args.map {|arg| gem_release[arg.to_s] }
  end

  def store(name = 'gem_metrics.yml')
    @store ||= YAML::Store.new(name)
  end

  def datetime
    p Time.now.utc.xmlschema
  end

  def update(store)
    timestamp = datetime
    my_gems.each do |gem|
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
