# encoding : utf-8
require 'curb'
require 'json'
require 'csv'

class DataGouvScrapper

  def initialize(*args)
    @organization = args[0];
    @base_url = "http://www.data.gouv.fr/api/3/action/"
    @base_url_qa = "http://qa.data.gouv.fr/api/1/"
    @public_url = "http://www.data.gouv.fr/fr/"
  end

  def get_url_from_organization(organization)
    "#{@base_url_qa}datasets?organization=#{organization}"
  end

  def get_url_from_dataset_id(dataset_id)
    "#{@base_url_qa}datasets/#{dataset_id}"
  end

  def get_public_url_from_dataset_name(dataset_name)
    "#{@public_url}dataset/#{dataset_name}"

  end

  def get_page_content_from_url(url)
    JSON.parse(Curl.get(url).body_str)
  end

  def get_tags_from_dataset(dataset)
    return [] if (!dataset['value']['tags'])
    tags = []
    dataset['value']['tags'].each do |tag|
      tags << tag['name']
    end
    return tags.uniq
  end

  def get_groups_from_dataset(dataset)
    return [] if (!dataset['value']['groups'])
    groups = []
    dataset['value']['groups'].each do |group|
      groups << group['name']
    end
    return groups.uniq
  end

  def get_resources_from_dataset(dataset)
    return [] if (!dataset['value']['resources'])
    resources = []
    dataset['value']['resources'].each do |r|
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
    return [] if (!dataset['value']['related'])
    final = []
    dataset['value']['related'].each do |r|
      related = {
        'description' => r['description'],
        'title' => r['title'],
        'url' => r['url'],
        'created' => r['created'],
        'type' => r['type'],
        'image_url' => r['image_url'],
        'id' => r['id'],
      }
      final << related
    end
    return final
  end

  def get_dataset_details_from_dataset_id(dataset_id)
      dataset = {}
      dataset_detail = get_page_content_from_url(get_url_from_dataset_id(dataset_id))

      dataset['name'] = dataset_detail['value']['name']
      dataset['id'] = dataset_detail['value']['id']
      dataset['notes'] = dataset_detail['value']['notes']
      dataset['title'] = dataset_detail['value']['title']
      dataset['territorial_coverage'] = dataset_detail['value']['territorial_coverage']
      dataset['territorial_coverage_granularity'] = dataset_detail['value']['territorial_coverage_granularity']
      dataset['temporal_coverage_from'] = dataset_detail['value']['temporal_coverage_from']
      dataset['temporal_coverage_to'] = dataset_detail['value']['temporal_coverage_to']
      dataset['license_title'] = dataset_detail['value']['license_title']
      dataset['license_url'] = dataset_detail['value']['license_url']
      dataset['revision_timestamp'] = dataset_detail['value']['revision_timestamp']
      
      dataset['tags'] = get_tags_from_dataset(dataset_detail)
      dataset['groups'] = get_groups_from_dataset(dataset_detail)
      dataset['resources'] = get_resources_from_dataset(dataset_detail)
      dataset['related'] = get_related_from_dataset(dataset_detail)

      return dataset
  end

  def get_organization_dataset(organization_name)
    data = []
    organization = get_page_content_from_url(get_url_from_organization(organization_name));
    datasets = organization['value']

    i = 0
    datasets.each do |id|
      i=i+1
      # break if i >3
      puts "Downloading dataset #{id}"
      data << get_dataset_details_from_dataset_id(id)
    end


    return data
  end

  def generate_json_file(data)
		File.open("#{@organization}.json", "w") do |file|
			file.write(JSON.pretty_generate(data))
		end
  end


  def get_files_for_csv_from_dataset(dataset)
    files = []
    dataset['resources'].each do |resource|
      files << "#{resource['name']}\n#{resource['format']}: #{resource['url']}"
    end
    files.join("\n\n")
  end





  def generate_csv_file(data)
    headers = [
      'id',
      'nom',
      'description',
      'url publique',
      'url API',
      'fichiers',
      'indicateur qualité',
      'qualité',
      'service producteur',
      'nombre réutilisation',
      'tags',
      'groups',
      'territorial coverage',
      'territorial coverage granularity',
      'temporal_coverage_from',
      'temporal_coverage_to',
      'license',
      'revision'
    ]
    p data

    CSV.open("#{@organization}.csv", "wb") do |file|
      file << headers
      data.each do |dataset|
        file << [
          dataset['name'],
          dataset['title'],
          dataset['notes'],
          get_public_url_from_dataset_name(dataset['name']),
          get_url_from_dataset_id(dataset['id']),
          get_files_for_csv_from_dataset(dataset),
          '',
          nil,
          nil,
          dataset['related'].size,
          dataset['tags'].join(', '),
          dataset['groups'].join(', '),
          dataset['territorial_coverage'],
          dataset['territorial_coverage_granularity'],
          dataset['temporal_coverage_from'],
          dataset['temporal_coverage_to'],
          "#{dataset['license_title']} / #{dataset['license_url']}",
          dataset['revision_timestamp']
        ]
      end
    end
  end



  def run
    data = get_organization_dataset(@organization)
    puts "Generating #{@organization}.json"
    generate_json_file(data)
    generate_csv_file(data)
    puts data
  end


end
DataGouvScrapper.new(*ARGV).run()
