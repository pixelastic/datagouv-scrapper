# Datagouv Scrapper

This tool was built during the Open Data 2014 Hackathon in Paris.

The goal was to get data from http://data.gouv.fr/ in a more easily readable
way for human. We wanted to get a simple spreadsheet to manually check each
file to see if the data contained in the downloadable ressources were easy to
use or not.

The tool will generate json and csv file by requesting the CKAN API exposed by
data.gouv.fr, ask for an organization, loop through all associated packages,
request the api for each of these packages, loop through their associated items
and aggregate all this data to form a nicely coherent list.
