class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    # ユーザ情報確認用
    # pp auth
    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)
    session[:user_id] = user.id
    User.update_with_omniauth(user, auth)
    redirect_to root_url, notice: "Signed in!"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: "Signed out!"
  end
end
