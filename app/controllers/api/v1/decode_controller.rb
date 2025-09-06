class Api::V1::DecodeController < ApplicationController
  def show
    if params[:slug]
      original_url = ShortLink.find_by_slug(params[:slug])
      error_message = "Short URL not found"
    elsif params[:url]
      original_url = ShortLink.find_by_url(params[:url])
      error_message = "Short URL not found"
    else
      render json: { error: "Slug or URL parameter required" }, status: :bad_request
      return
    end

    if original_url
      render json: { original_url: original_url }
    else
      render json: { error: error_message }, status: :not_found
    end
  end
end
