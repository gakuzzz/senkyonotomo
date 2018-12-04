class BaseController < ApplicationController
  # before_action :http_authenticate!
  before_action :authenticate_user!

  rescue_from Exception, with: :render_500

  def render_500(exception)
    # output_exception_log(exception, :error)
    return if performed? # devise gemで既にrender済のケース
    render json: { message: exception }, status: :internal_server_error
  end
end
