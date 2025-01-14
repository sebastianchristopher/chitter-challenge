require 'sinatra/base'
require 'sinatra/flash'
require 'pg'

require_relative 'lib/database_connection_setup'
require_relative './lib/email'
require_relative './lib/mailer'
require_relative './lib/mailer_setup'
require_relative 'lib/peep'
require_relative 'lib/user'

class ApplicationController < Sinatra::Base
  enable :method_override, :sessions
  register Sinatra::Flash

  get '/' do
    if session[:user]
      @user = session[:user]
      @email = session[:user].email
    end
    @peeps = Peep.all
    erb(:index)
  end

  get '/peeps/:id' do
    if session[:user]
      @user = session[:user]
      @email = session[:user].email
    end
    @peeps = Peep.find_user(params[:id])
    erb(:index)
  end

  get '/peep/new' do
    erb(:'peeps/new')
  end

  post '/peeps' do
    Peep.create(params[:content], session[:user].id)
    redirect '/'
  end

  get '/sessions/new' do
    erb(:'sessions/new')
  end

  post '/sessions' do
    @user = User.authenticate(params[:email], params[:password])
    if !@user.nil?
      session[:user] = @user
      flash[:confirmation] = "Welcome, #{@user.email}"
    else
      flash[:notice] = 'Your email and/or password was incorrect'
    end
    redirect '/'
  end

  get '/users/new' do
    erb(:'users/new')
  end

  post '/users' do
    @user = User.create(params[:email], params[:password])
    if @user.is_a?(User)
      flash[:confirmation] = "#{@user.email} is now signed up"
      session[:user] = @user
      Mailer.send(WelcomeEmail.new(@user))
    else
      flash[:confirmation] = @user
    end
    redirect '/'
  end

  post '/sessions/destroy' do
    session.clear
    flash[:notice] = 'You have signed out.'
    redirect('/')
  end

  run! if app_file == $PROGRAM_NAME
end
