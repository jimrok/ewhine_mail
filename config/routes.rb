EwhineMail::Application.routes.draw do
	
	scope "ewhine_mail" do
		root :to => 'mails#index'
		
		match '/' => "mails#index"
		match "connector" => "connector#service", :via => "post"
		match "connector/publish" => "connector#publish", :via => ["get","post"]
		match ':controller(/:action(/:id))(.:format)'
	end
end
