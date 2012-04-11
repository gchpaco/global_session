class HappyController < ApplicationController

  def index
    render :text => session.to_json
  end

  def update
    key = params[:session][:key].to_sym
    val = params[:session][:value]
    session[key] = val
    redirect_to :action => :index
  end

  def destroy
    key = params[:key].to_sym
    session.delete(key)
    redirect_to :action => :index
  end

end
