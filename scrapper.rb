# encoding : utf-8
require 'curb'
require 'json'
# Loop sur packages
# télécharge le package
# loop sur ressources
# loop sur related_list


class DataGouvScrapper

  def initialize(*args)
    @organization = args[0];
    @base_url = "http://www.data.gouv.fr/api/3/action/"
  end

  def get_url_from_organization(organization)
    "#{@base_url}organization_show?id=#{organization}"
  end

  def get_url_from_dataset(dataset)
    "#{@base_url}package_show?id=#{dataset}"
  end

  def get_page_content_from_url(url)
    JSON.parse(Curl.get(url).body_str)
  end

  def get_tags_from_dataset(dataset)
    return [] if (!dataset['result']['tags'])
    tags = []
    dataset['result']['tags'].each do |tag|
      tags << tag['name']
    end
    return tags.uniq
  end

  def get_groups_from_dataset(dataset)
    return [] if (!dataset['result']['groups'])
    groups = []
    dataset['result']['groups'].each do |group|
      groups << group['name']
    end
    return groups.uniq
  end

  def get_resources_from_dataset(dataset)
    return [] if (!dataset['result']['resources'])
    resources = []
    dataset['result']['resources'].each do |r|
      resource = {
        'created' => r['created'],
        'revision_timestamp' => r['revision_timestamp'],
        'name' => r['name'],
        'description' => r['description'],
        'format' => r['format'],
        'url' => r['url']
      }
      resources << resource
    end
    return resources
  end

  def run
    data = []
    organization = get_page_content_from_url(get_url_from_organization(@organization));
    datasets = organization['result']['packages']

    # i = 0
    datasets.each do |d|
      # i=i+1
      # break if i >3

      dataset = {
        'name' => d['name'],
        'notes' => d['notes'],
        'title' => d['title']
      }
      
      puts "Downloading #{d['title']}"
      dataset_detail = get_page_content_from_url(get_url_from_dataset(d['name']))

      dataset['territorial_coverage'] = dataset_detail['result']['territorial_coverage']
      dataset['territorial_coverage_granularity'] = dataset_detail['result']['territorial_coverage_granularity']
      dataset['temporal_coverage_from'] = dataset_detail['result']['temporal_coverage_from']
      dataset['temporal_coverage_to'] = dataset_detail['result']['temporal_coverage_to']
      dataset['license_title'] = dataset_detail['result']['license_title']
      dataset['license_url'] = dataset_detail['result']['license_url']
      dataset['revision_timestamp'] = dataset_detail['result']['revision_timestamp']

      dataset['tags'] = get_tags_from_dataset(dataset_detail)
      dataset['groups'] = get_groups_from_dataset(dataset_detail)
      dataset['resources'] = get_resources_from_dataset(dataset_detail)

      data << dataset
    end

    puts "Generating #{@organization}.json"
		File.open("#{@organization}.json", "w") do |file|
			file.write(JSON.pretty_generate(data))
		end
  end


end
DataGouvScrapper.new(*ARGV).run()
