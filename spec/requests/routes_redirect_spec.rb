require 'rails_helper'

RSpec.describe 'Legacy Routes', type: :request do
  before { Rails.cache.clear }

  describe 'POST /encode' do
    it 'works the same as /api/v1/encode' do
      post '/encode', params: { url: 'https://example.com' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['short_url']).to match(/http:\/\/www\.example\.com\/\w+/)
    end
  end

  describe 'GET /decode/:slug' do
    it 'works the same as /api/v1/decode/:slug' do
      link = ShortLink.create!(original_url: 'https://example.com')
      get "/decode/#{link.slug}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['original_url']).to eq('https://example.com')
    end
  end

  describe 'GET /decode with query parameter' do
    it 'works the same as /api/v1/decode with query parameter' do
      link = ShortLink.create!(original_url: 'https://example.com')
      short_url = "http://localhost:3000/#{link.slug}"
      
      get "/decode?url=#{CGI.escape(short_url)}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['original_url']).to eq('https://example.com')
    end

    it 'returns error for empty query parameter' do
      get '/decode?url='
      
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Short URL not found')
    end

    it 'returns error when no parameters provided' do
      get '/decode'
      
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Slug or URL parameter required')
    end
  end
end