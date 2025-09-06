require 'rails_helper'

RSpec.describe 'POST /api/v1/encode', type: :request do
  before { Rails.cache.clear }

  context 'with valid URL' do
    it 'creates a new short link' do
      expect {
        post '/api/v1/encode', params: { url: 'https://example.com' }
      }.to change(ShortLink, :count).by(1)
    end

    it 'returns short URL in JSON' do
      post '/api/v1/encode', params: { url: 'https://example.com' }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['short_url']).to match(/http:\/\/www\.example\.com\/\w+/)
    end

    it 'returns existing short link for duplicate URL' do
      link = ShortLink.create!(original_url: 'https://example.com')
      
      expect {
        post '/api/v1/encode', params: { url: 'https://example.com' }
      }.not_to change(ShortLink, :count)
      
      json = JSON.parse(response.body)
      expect(json['short_url']).to include(link.slug)
    end

    it 'handles URLs with different protocols' do
      post '/api/v1/encode', params: { url: 'http://example.com' }
      expect(response).to have_http_status(:ok)
    end

    it 'handles URLs with paths and query params' do
      post '/api/v1/encode', params: { url: 'https://example.com/path?param=value' }
      expect(response).to have_http_status(:ok)
    end
  end

  context 'with invalid URL' do
    it 'returns error for missing URL' do
      post '/api/v1/encode', params: {}
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include("Original url can't be blank")
    end

    it 'returns error for empty URL' do
      post '/api/v1/encode', params: { url: '' }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include("Original url can't be blank")
    end

    it 'returns error for nil URL' do
      post '/api/v1/encode', params: { url: nil }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include("Original url can't be blank")
    end
  end

  context 'edge cases' do
    it 'handles very long URLs' do
      long_url = 'https://example.com/' + 'a' * 2000
      post '/api/v1/encode', params: { url: long_url }
      
      expect(response).to have_http_status(:ok)
    end

    it 'handles URLs with special characters' do
      special_url = 'https://example.com/path?q=hello%20world&foo=bar#section'
      post '/api/v1/encode', params: { url: special_url }
      
      expect(response).to have_http_status(:ok)
    end

    it 'handles international domain names' do
      post '/api/v1/encode', params: { url: 'https://münchen.de' }
      expect(response).to have_http_status(:ok)
    end

    it 'handles localhost URLs' do
      post '/api/v1/encode', params: { url: 'http://localhost:3000' }
      expect(response).to have_http_status(:ok)
    end

    it 'handles IP addresses' do
      post '/api/v1/encode', params: { url: 'http://192.168.1.1' }
      expect(response).to have_http_status(:ok)
    end
  end

  context 'caching behavior' do
    it 'uses cached result on second request' do
      url = 'https://cached-example.com'
      
      # First request
      post '/api/v1/encode', params: { url: url }
      first_response = JSON.parse(response.body)
      
      # Second request should use cache
      post '/api/v1/encode', params: { url: url }
      second_response = JSON.parse(response.body)
      
      expect(first_response['short_url']).to eq(second_response['short_url'])
    end
  end
end