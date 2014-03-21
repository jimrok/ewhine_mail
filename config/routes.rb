EwhineMail::Application.routes.draw do
   match "connector" => "connector#service", :via => "post"
   match "connector/publish" => "connector#publish", :via => ["get","post"]
   match ':controller(/:action(/:id))(.:format)'
end
