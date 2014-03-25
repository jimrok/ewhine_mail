EwhineMail::Application.routes.draw do
	root :to => 'mails#index'
	scope "ewhine_mail" do
		match '/' => "mails#index"
		match "connector" => "connector#service", :via => "post"
		match "connector/publish" => "connector#publish", :via => ["get","post"]
		match ':controller(/:action(/:id))(.:format)'
	end
end
