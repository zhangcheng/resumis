require File.dirname(__FILE__)+'/application'

home = ENV["RESUMIS_DEPLOY_ROOT"]
port = ENV["RESUMIS_HTTP_PORT"].presence || ENV["PORT"]

if Rails.env.production?
  listen "/tmp/resumis-unicorn.sock", backlog: 64
  worker_processes 2
else
  listen port, tcp_nopush: true
  worker_processes 1
end

preload_app true
timeout 30

Unicorn::Configurator::DEFAULTS[:logger].formatter = Logger::Formatter.new

stderr_path "log/unicorn.log"
stdout_path "log/unicorn.log"

pid "#{home}/shared/pids/unicorn.pid"

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end
