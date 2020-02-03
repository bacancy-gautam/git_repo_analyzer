Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get '/git_analysis' => 'git_org_analyzers#open_source_repositories'
end
