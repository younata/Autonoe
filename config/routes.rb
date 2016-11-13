Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post 'generate/epub', to: 'generator#epub'
    end
  end
end
