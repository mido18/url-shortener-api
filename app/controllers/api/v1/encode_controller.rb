class Api::V1::EncodeController < ApplicationController
  wrap_parameters false
  
  def create
    url = url_params
    return unless url

    link = ShortLink.find_or_create_by_url(url)

    if link&.persisted?
      render json: { short_url: link.full_short_url(request) }
    elsif link
      render json: { error: link.errors.full_messages }, status: :unprocessable_entity
    else
      render json: { error: ["Unable to create short link"] }, status: :unprocessable_entity
    end
  end

  private

  def url_params
    url = params.permit(:url)[:url]
    if url.blank?
      render json: { error: ["Original url can't be blank"] }, status: :unprocessable_entity
      return nil
    end
    url
  end
end
