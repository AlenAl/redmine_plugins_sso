# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'sso', :to => 'sso#index'
get 'sso/logout', :to => 'sso#logout'