#!/usr/bin/env ruby
require 'fileutils'
require 'pathname'
require 'openssl'


install_path = "/home/ewhine/deploy/ewhine_mail"
default_ruby_encoder_path = "/home/ewhine/rubyencoder-2.0"
project_id = "htdev"
project_key = "hataizhengquan2014"
current_path = File.expand_path('../', __FILE__)




class Build

  def initialize(options)
    @package_gems = options[:package_gems]
    @default_ruby_encoder_path = options[:default_ruby_encoder_path]
    @project_id = options[:project_id]
    @project_key = options[:project_key]
    @install_path = options[:install_path]
  end

  def tar

    work_path = File.expand_path('../', __FILE__)

    temp = "#{work_path}/ewhine_mail_pkg"
    FileUtils.rm_rf(temp)
    FileUtils.mkdir_p(temp)


    Dir.chdir(work_path) do

      puts "install bundles..."
      system "bundle install --local"

      puts "rake assets:precompile ..."
      system "bundle exec rake RAILS_ENV=production RAILS_GROUPS=assets assets:precompile"

      puts "copy files to temp directory ..."

      FileUtils.cp_r("app", temp)
      #FileUtils.cp_r("bin", temp)
      FileUtils.cp_r("config", temp)
      FileUtils.cp_r("db", temp)
      FileUtils.cp_r("lib", temp)
      FileUtils.cp_r("public", temp)
      FileUtils.cp_r("script", temp)
      FileUtils.cp("config.ru", temp)
      FileUtils.cp("Gemfile", temp)
      FileUtils.cp("Gemfile.lock", temp)
      FileUtils.cp("Gemfile~", temp)
      FileUtils.cp("Rakefile", temp)
      FileUtils.cp("build.rb", temp)

    end

    FileUtils.cp_r("#{work_path}/public/assets", "#{temp}")


    if Dir.exist?(@default_ruby_encoder_path) && File.exist?("#{@default_ruby_encoder_path}/bin/rubyencoder")
      ruby_encoder_path = @default_ruby_encoder_path
      puts "start encode code ..."
      Dir.chdir("#{ruby_encoder_path}/bin") do
        puts Dir.getwd
        ["api", "controllers", "helpers", "jobs", "mailers", "models"].each do |dir|
          system("./rubyencoder -r --external #{@project_id}.lic --projid #{@project_id} --projkey #{@project_key} --encoding UTF-8 --ruby 2.0.0 #{temp}/app/#{dir}")
        end

        ["cells"].each do |dir|
          system("./rubyencoder -r --external #{@project_id}.lic --projid #{@project_id} --projkey #{@project_key} --encoding UTF-8 --ruby 2.0.0 #{temp}/app/#{dir}/*.rb")
        end

        ["mqtt_agent"].each do |dir|
          system("./rubyencoder -r --external #{@project_id}.lic --projid #{@project_id} --projkey #{@project_key} --encoding UTF-8 --ruby 2.0.0 #{temp}/lib/#{dir}/*.rb")
        end

        FileUtils.cp_r("../rgloader", temp)
      end

    else
      puts "No encoder found,leave code without encoding!!!"
      exit
    end


    puts "tar code ..."
    Dir.chdir(temp) do
      system("find  app  -name  '*.bak'  -type  f -exec  rm  -rf  {} \\;")

      FileUtils.rm_rf(%w(config/deploy config/thin config/environments/production config/environments/staging))
      if @package_gems then
        FileUtils.mkdir_p("#{temp}/vendor")
        FileUtils.cp_r("#{work_path}/vendor/cache", "#{temp}/vendor")
        #system("tar czf ../ewhine.tar.gz ./config.ru ./Gemfile ./Gemfile.lock ./Gemfile~ ./Rakefile ./build.rb ./app/api ./app/cells ./app/controllers ./app/helpers ./app/jobs ./app/mailers ./app/models ./app/uploaders ./app/views ./app/views_mobile ./rgloader ./config ./db ./lib ./public ./script ./assets ./vendor")
        #system("tar czf ../ewhine.tar.gz ./config.ru ./Gemfile ./Gemfile.lock ./Gemfile~ ./Rakefile ./build.rb ./app/api ./app/cells ./app/controllers ./app/helpers ./app/jobs ./app/mailers ./app/models ./app/uploaders ./app/views ./app/views_mobile ./rgloader ./config ./db ./lib ./public ./script ./assets")
      end
    end

    system("tar czf ewhine_mail_pkg.tar.gz ./ewhine_mail_pkg")

    #FileUtils.rm_rf(temp)
    puts "finished!"

  end

  def setup

    default_install_path = @install_path
    loop do

      puts "\nEnter install path (default:#{default_install_path}):"
      path = STDIN.gets().chomp()

      if path.empty? and default_install_path then
        path = default_install_path
      end

      if Dir.exist?("#{path}/current") then
        puts "install path not empty! please choose another directory!"
        next
      else
        default_install_path = path
        break
      end
    end


    if !Dir.exist?("#{default_install_path}/current") then

      releases_path = "#{default_install_path}/releases"

      # Create a new release path.
      version = Time.now.utc.strftime("%Y%m%d%H%M%S")

      FileUtils.mkdir_p("#{releases_path}/#{version}")
      FileUtils.mkdir_p("#{releases_path}/#{version}/tmp")

      FileUtils.mkdir_p("#{default_install_path}/efiles/contents")
      FileUtils.mkdir_p("#{default_install_path}/efiles/photos")
      FileUtils.mkdir_p("#{default_install_path}/shared/log")
      FileUtils.mkdir_p("#{default_install_path}/shared/system")
      FileUtils.mkdir_p("#{default_install_path}/shared/pids")


      FileUtils.symlink("#{releases_path}/#{version}", "#{default_install_path}/current")
      FileUtils.symlink("#{default_install_path}/efiles/contents", "#{releases_path}/#{version}/contents")
      FileUtils.symlink("#{default_install_path}/efiles/photos", "#{releases_path}/#{version}/photos")
      FileUtils.symlink("#{default_install_path}/shared/log", "#{releases_path}/#{version}/log")
      FileUtils.symlink("#{default_install_path}/shared/pids", "#{releases_path}/#{version}/tmp/pids")

    end


  end

  def install_db


  end

  def clean

    default_path = @install_path


    Dir.chdir("#{default_path}/current") do
      puts "Staring clean the database..."
      system('bundle exec rake db:drop db:create RAILS_ENV=production')
      system('bundle exec rake db:schema:load RAILS_ENV=production')

      puts "Staring clean the redis..."
      system('redis-cli -p 6379 flushall')

      puts "initialize database with seed file..."
      system('bundle exec rake db:seed RAILS_ENV=production')
    end

    puts "Staring clean the uploaded files..."
    FileUtils.rm_rf("#{default_path}/efiles/contents")
    FileUtils.rm_rf("#{default_path}/efiles/photos")

    FileUtils.mkdir_p("#{default_path}/efiles/contents")
    FileUtils.mkdir_p("#{default_path}/efiles/photos")

  end



  def install

    default_path = @install_path

    # check the releases_path
    if !Dir.exist?(default_path) then
      puts "Not found releases_path: #{default_path}"
      exit
    end

    releases_path = "#{default_path}/releases"
    path = "#{default_path}"
    current_path = "#{default_path}/current"

    deploy_temp_path = File.expand_path("../",__FILE__)

    app_backup_path = "#{default_path}/app_backup"
    FileUtils.rm_rf(app_backup_path)
    FileUtils.mkdir_p(app_backup_path)



    if !Dir.exist?("#{deploy_temp_path}/vendor") and File.exist?("#{path}/current/Gemfile.lock") then
      new_gem = ::Digest::MD5.hexdigest(File.read("#{deploy_temp_path}/Gemfile.lock"))
      old_gem = ::Digest::MD5.hexdigest(File.read("#{path}/current/Gemfile.lock"))

      if new_gem != old_gem then
        puts "Gemfile.lock in #{releases_path} is not same as this code."
        exit
      end

    end

    if Dir.exist?("#{path}/current/app") then
      FileUtils.mv("#{path}/current/app", app_backup_path)
      FileUtils.mv("#{path}/current/config", app_backup_path)
      FileUtils.mv("#{path}/current/db", app_backup_path)
      FileUtils.mv("#{path}/current/lib", app_backup_path)
      FileUtils.mv("#{path}/current/public", app_backup_path)
      FileUtils.mv("#{path}/current/script", app_backup_path)
      FileUtils.mv("#{default_path}/shared/assets", app_backup_path)

      if Dir.exist?("#{deploy_temp_path}/vendor") then
        FileUtils.mkdir_p("#{app_backup_path}/vendor")
        FileUtils.mv("#{path}/current/vendor/cache", "#{app_backup_path}/vendor")
      end
    end


    current_path = File.realpath("#{path}/current")


    FileUtils.mv("#{deploy_temp_path}/app", "#{path}/current")
    FileUtils.mv("#{deploy_temp_path}/config", "#{path}/current")
    FileUtils.mv("#{deploy_temp_path}/db", "#{path}/current")
    FileUtils.mv("#{deploy_temp_path}/lib", "#{path}/current")
    FileUtils.mv("#{deploy_temp_path}/public", "#{path}/current")
    FileUtils.mv("#{deploy_temp_path}/script", "#{path}/current")
    FileUtils.mv("#{deploy_temp_path}/assets", "#{default_path}/shared/assets")

    if Dir.exist?("#{deploy_temp_path}/vendor") then
      FileUtils.mkdir_p("#{path}/current/vendor")
      FileUtils.mv("#{deploy_temp_path}/vendor/cache", "#{path}/current/vendor",:force=>true)
    end

    FileUtils.rm_rf("#{current_path}/public/assets")
    FileUtils.rm_rf("#{current_path}/public/system")
    FileUtils.symlink("#{default_path}/shared/assets", "#{current_path}/public/assets")
    FileUtils.symlink("#{default_path}/shared/system", "#{current_path}/public/system")

    FileUtils.mv("#{deploy_temp_path}/rgloader", "#{path}/current",:force=>true) if Dir.exist?("#{deploy_temp_path}/rgloader")
    FileUtils.mv("#{deploy_temp_path}/config.ru", "#{path}/current",:force=>true)
    FileUtils.mv("#{deploy_temp_path}/Rakefile", "#{path}/current",:force=>true)
    FileUtils.mv("#{deploy_temp_path}/Gemfile", "#{path}/current",:force=>true)
    FileUtils.mv("#{deploy_temp_path}/Gemfile.lock", "#{path}/current",:force=>true)
    FileUtils.mv("#{deploy_temp_path}/Gemfile~", "#{path}/current",:force=>true)
    FileUtils.cp("#{deploy_temp_path}/build.rb", "#{path}/current")



    if !Dir.exist?("#{current_path}/tmp/pids") then
      FileUtils.symlink("#{default_path}/efiles/contents", "#{current_path}/contents")
      FileUtils.symlink("#{default_path}/efiles/photos", "#{current_path}/photos")
      FileUtils.symlink("#{default_path}/shared/log", "#{current_path}/log")
      FileUtils.symlink("#{default_path}/shared/pids", "#{current_path}/tmp/pids")
    end

    puts "bundle install ..."

    Dir.chdir("#{path}/current") do

      system("bundle install --local --gemfile Gemfile --path #{default_path}/shared/bundle --deployment --quiet --without development test")
      # system("bundle exec rake db:migrate RAILS_ENV=\"production\" ")

    end


    # puts "Clean memcached..."
    # system("echo 'flush_all' | nc -q 2 127.0.0.1 11211 ")

    #FileUtils.rm_rf("#{deploy_temp_path}")
    # puts "restart server ..."
    # pid = `cat #{current_path}/tmp/pids/unicorn.pid`.strip
    # unless pid.empty? then
    #   system("kill -QUIT #{pid}")
    # end

    # system("cd #{releases_path}/#{version} && RAILS_ENV=production bundle exec unicorn_rails -c config/unicorn.rb -D")

    # Dir.foreach(releases_path) do |d|
    #   if d.start_with?("20") && ![current_dir, version].include?(d) then
    #     FileUtils.rm_rf("#{releases_path}/#{d}")
    #   end

    #   unless Dir.exist?("#{current_path}/rgloader")
    #     FileUtils.rm_rf(current_path)
    #   end
    # end

    puts "finished!"

  end

  def upgrade

  end


end

puts "current path:#{current_path}"

package_all = false

if ARGV.any? then

  if ( "tar" == ARGV.first) then

    if ARGV[1] == "all" then
      package_all = true
    end

    build = Build.new(:package_gems => package_all,:default_ruby_encoder_path =>default_ruby_encoder_path,:project_id=>project_id,:project_key=>project_key)
    build.tar

  elsif ("setup" == ARGV.first) then
    build = Build.new(:install_path=>install_path)
    build.setup

  elsif ("install" == ARGV.first) then
    build = Build.new(:install_path=>install_path)
    build.install

  elsif ("clean" == ARGV.first) then

    puts "\nAll data in the database and redis will be destroy,Are you sure do that(y/n)?:"
    do_clean = STDIN.gets().chomp()

    if ('y' == do_clean or 'Y' == do_clean) then
      build = Build.new(:install_path=>install_path)
      build.clean
    end

  end

end
