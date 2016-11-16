Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post 'generate/epub', to: 'generator#epub'
      post 'generate/mobi', to: 'generator#mobi'
    end
  end
end
