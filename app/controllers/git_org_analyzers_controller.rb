class GitOrgAnalyzersController < ApplicationController


  def open_source_repositories
  	@repository_details = GitRepositoryAnalyzer.new.analyze_github_repo
  end
end
