require 'gems'
require 'yaml/store'
require 'time'
require 'logger'

class GemDownloads
  def initialize(store = store)
    @logger = Logger.new('debugging.log')
    store = new_store('zlatest_downloads.yml')
    @logger.info 'Getting downloads'
    latest_downloads(store)

    store = new_store('zgem_metrics.yml')
    @logger.info 'Updating gem metrics'
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
  # Gems.downloads name, version, from, to # number of downloads by day

  def downloads(gem_name, from=nil, to=Date.today)
    @result = {}
    puts
    print gem_name
    gem  = Gems.info(gem_name)
    @result['urls'] = [gem['homepage_uri'], gem['source_code_uri'], gem['project_uri']]
    @result['authors'] ||= gem['authors']
     gem_releases(gem_name).map do |release|
       # let's see which updated gems don't have licenses
       @result['license'] ||= release['licenses']
       version = release['number']
       print " #{version}"
       @result[version] ||= {}
       @result[version]['built_at'] = release['built_at']

       downloads = Gems.downloads(gem_name, version, from, to)
       if downloads.respond_to?(:reject!)
         downloads.reject!{|d,c| c==0}
       else
         downloads = {'error' => downloads}
       end

       @result[version]['downloads'] ||= {}
       downloads.each do |date, count|
         @result[version]['downloads'][date] = count
       end
     end
     @logger.info @result.inspect
     @result
  end
  def latest
    @latest ||= new_gems.map{|g|g['name']} | updated_gems.map{|g|g['name']}
  end
  def new_gems
    Gems.latest
  end
  def updated_gems
    Gems.just_updated
  end
  def latest_downloads(store)
    latest.each do |gem_name|
      @logger.info "Getting download info for #{gem_name}"
      store.transaction do
        store[gem_name] = downloads(gem_name)
      end
    end
  end
  def gems
    my_gems.concat(extra_gems).
      reject! {|gem| rejected_gems.include?(gem['name']) }
  end
  # ["authors", "built_at", "description", "downloads_count", "number", "summary", "platform", "prerelease", "licenses"]
  def gem_releases(gem_name)
    releases = Gems.versions(gem_name)
    if releases.is_a?(String)
      @logger.error "#{gem_name.inspect} returned releases #{releases}"
      []
    else
      releases
    end
  end

  def extra_gems
    %w(reek ruby_parser rails_best_practices flog flay cane churn turbulence).map do |gem_name|
      Gems.info(gem_name)
    end
  end

  def rejected_gems
    @rejected_gems ||= %w(bf4-metrical bf4-metric_fu bf4-yui-rails bf4-browsercms bf4-bcms_news)
  end

  def new_store(name = 'zgem_metrics.yml')
    @store = YAML::Store.new(name)
  end

  def store
    @store ||= new_store
  end

  def datetime
    p Time.now.utc.xmlschema
  end

  def update(store)
    timestamp = datetime
    gems.each do |gem|
      puts
      gem_name = gem['name']
      print gem_name
      dependencies = gem['dependencies']
      info = gem['info']
      url = gem['homepage_uri'] || gem['source_code_uri'] || gem['project_uri']
      store.transaction do
        store[gem_name] ||= {}
        store[gem_name]['info'] = info
        store[gem_name]['url'] = url
        gem_releases(gem_name).each do |gem_release|
          version =  gem_release['number']
          print " #{version}"
          count =       gem_release['downloads_count']
          build_date =  gem_release['built_at']
          @logger.info "Updating downloads for #{gem_name} version #{version} built at #{build_date} to #{count} on #{timestamp}"
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
