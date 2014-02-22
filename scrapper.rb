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

  def get_url_from_related(dataset)
    "#{@base_url}related_list?id=#{dataset}"
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

  def get_related_from_dataset(dataset)
    related_list = get_page_content_from_url(get_url_from_related(dataset['result']['name']))
    return [] if (!related_list['result'])
    final = []
    related_list['result'].each do |r|
      related = {
        'description' => r['description'],
        'title' => r['title'],
        'url' => r['url'],
        'created' => r['created'],
        'type' => r['type'],
        'image_url' => r['image_url']
      }
      final << related
    end
    return final
  end

  def get_dataset_details(dataset_name)
      dataset = {}
      dataset_detail = get_page_content_from_url(get_url_from_dataset(dataset_name))

      dataset['name'] = dataset_detail['result']['name']
      dataset['notes'] = dataset_detail['result']['notes']
      dataset['title'] = dataset_detail['result']['title']
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
      dataset['related'] = get_related_from_dataset(dataset_detail)

      return dataset
  end

  def get_organization_dataset(organization_name)
    data = []
    organization = get_page_content_from_url(get_url_from_organization(organization_name));
    datasets = organization['result']['packages']

    i = 0
    datasets.each do |d|
      i=i+1
      # break if i >3
      puts "Downloading #{d['title']}"
      data << get_dataset_details(d['name'])
    end

    return JSON.pretty_generate(data);
  end

  def run
    data = get_organization_dataset(@organization)
    puts "Generating #{@organization}.json"
		File.open("#{@organization}.json", "w") do |file|
			file.write(data)
		end
    puts data
  end


end
DataGouvScrapper.new(*ARGV).run()
