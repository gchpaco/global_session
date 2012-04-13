class HappyController < ApplicationController

  def index
    render :text => { :message => 'Be Happy!!!', :session => session }.to_json
  end

  def update
    key = params[:key].to_sym
    val = params[:value]
    session[key] = val
    redirect_to :action => :index
  end

  def destroy
    key = params[:key].to_sym
    session.delete(key)
    redirect_to :action => :index
  end

end
