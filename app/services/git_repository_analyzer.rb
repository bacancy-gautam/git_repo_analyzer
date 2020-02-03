
require 'graphql/client'
require 'graphql/client/http'
require 'graphql/client/schema'
require 'csv'

class GitRepositoryAnalyzer
  NUMBER_OF_LANGUAGES = 5

  HttpAdapter = GraphQL::Client::HTTP.new(ENV['URL']) do
    def headers(_context)
      {
        'Authorization' => "Bearer #{ENV['GITHUB_ACCESS_TOKEN']}",
        'User-Agent' => 'Ruby'
      }
    end
  end

  Schema = GraphQL::Client.load_schema(HttpAdapter)
  Client = GraphQL::Client.new(schema: Schema, execute: HttpAdapter)
  RepositoryQuery = Client.parse <<-'GRAPHQL'
    query($after: String) {
    organization(login: "google"){
      name
      url
      repositories(privacy: PUBLIC, first: 100, after: $after) {
        totalCount
        pageInfo {
          hasNextPage
          endCursor
        }
        edges {
          node {
            id
            name
            createdAt
            languages(first: 10)
            {
              edges {
                node {
                  name
                }
              }
            }
          }
        }
      }
    }
  }
  GRAPHQL

  def initialize
    @has_next_page = true
    @end_cursor = nil
    @repositories = []
  end

  def analyze_github_repo
    set_list_of_repositories

    {
      repositories: @repositories,
      most_languages: most_languages,
      least_languages: least_languages
    }
    
  end

 

  # def add_headers_to_csv
  #   CSV.open('repo_results.csv', 'a+') do |csv|
  #     csv << ['Repository Name', 'Languages', 'Repository Created At']
  #   end
  # end

  def set_list_of_repositories
    while @has_next_page
      result = Client.query(RepositoryQuery, variables: { after: @end_cursor })
      repositories = result.data.organization.repositories
      @has_next_page = repositories.page_info.has_next_page
      @end_cursor = repositories.page_info.end_cursor
      repositories.edges.map(&:node).each do |node|
        languages = node.languages.edges.map(&:node).map(&:name).map(&:to_s)
        @repositories << {repository_name: node.name, repository_languages: languages.join(','), created_at: node.created_at}
      end
    end
  end

  def most_languages
    languages.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by {|k,v| v}.reverse.first(5)
    # languages.uniq.max_by(NUMBER_OF_LANGUAGES) { |ele| languages.count(ele) }.join(', ')
  end

  def least_languages
    languages.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by {|k,v| v}.first(5)
    # languages.uniq.min_by(NUMBER_OF_LANGUAGES) { |ele| languages.count(ele) }.join(', ')
  end

  def languages
    @languages ||= @repositories.map{ |repo| repo[:repository_languages]}.join(',').split(',').reject(&:empty?)
  end
end
