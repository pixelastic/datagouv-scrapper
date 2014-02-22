# encoding : utf-8
require "open-uri"
# scrapper ministere-de-l-interieur
# Télécharge organization_show
# Loop sur packages
# télécharge le package
# loop sur ressources


class DataGouvScrapper

  def initialize(*args)
    @organization = args[0];
    @base_url = "http://www.data.gouv.fr/api/3/action/"
  end

  def get_url_from_organization(organization)
    "#{@base_url}organization_show?id=#{organization}"
  end

  def get_page_content_from_url(url)
    open(url, 'r').read
  end


  def run
    content = get_page_content_from_url(get_url_from_organization(@organization));
    puts content

  end


end
DataGouvScrapper.new(*ARGV).run()
