require 'rails_helper'

RSpec.describe 'GET /api/v1/decode', type: :request do
  before { Rails.cache.clear }

  describe 'decode by slug' do
    context 'with valid slug' do
      it 'returns original URL' do
        link = ShortLink.create!(original_url: 'https://example.com')
        
        get "/api/v1/decode/#{link.slug}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['original_url']).to eq('https://example.com')
      end

      it 'uses cached result if available' do
        Rails.cache.write('slug:cached123', 'https://cached.com')
        
        get '/api/v1/decode/cached123'
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['original_url']).to eq('https://cached.com')
      end

      it 'caches result after database lookup' do
        link = ShortLink.create!(original_url: 'https://example.com')
        
        get "/api/v1/decode/#{link.slug}"
        
        expect(Rails.cache.read("slug:#{link.slug}")).to eq('https://example.com')
        expect(Rails.cache.read("url:https://example.com")).to eq(link.slug)
      end
    end

    context 'with invalid slug' do
      it 'returns not found error' do
        get '/api/v1/decode/nonexistent'
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Short URL not found')
      end

      it 'handles empty slug' do
        get '/api/v1/decode/'
        
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'decode by URL query parameter' do
    context 'with valid short URL' do
      it 'decodes short URLs passed as URL parameter' do
        link = ShortLink.create!(original_url: 'https://example.com')
        short_url = "http://localhost:3000/#{link.slug}"
        
        get "/api/v1/decode?url=#{CGI.escape(short_url)}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['original_url']).to eq('https://example.com')
      end

      it 'handles short URLs from different domains' do
        link = ShortLink.create!(original_url: 'https://example.com')
        short_url = "https://short.ly/#{link.slug}"
        
        get "/api/v1/decode?url=#{CGI.escape(short_url)}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['original_url']).to eq('https://example.com')
      end
    end

    context 'with invalid URL' do
      it 'returns not found error for non-existent short URL' do
        get '/api/v1/decode?url=http://localhost:3000/nonexistent'
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Short URL not found')
      end

      it 'returns not found error for original URLs (not short URLs)' do
        ShortLink.create!(original_url: 'https://example.com')
        
        get '/api/v1/decode?url=https://example.com'
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Short URL not found')
      end

      it 'handles empty URL parameter' do
        get '/api/v1/decode?url='
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Short URL not found')
      end
    end
  end

  describe 'parameter validation' do
    it 'returns error when no parameters provided' do
      get '/api/v1/decode'
      
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Slug or URL parameter required')
    end

    it 'prioritizes slug over URL when both provided' do
      link = ShortLink.create!(original_url: 'https://slug-priority.com')
      
      get "/api/v1/decode/#{link.slug}?url=https://other.com"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['original_url']).to eq('https://slug-priority.com')
    end
  end

  describe 'edge cases' do
    it 'handles very long URLs' do
      long_url = 'https://example.com/' + 'a' * 2000
      link = ShortLink.create!(original_url: long_url)
      
      get "/api/v1/decode/#{link.slug}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['original_url']).to eq(long_url)
    end

    it 'handles international domain names' do
      intl_url = 'https://münchen.de'
      link = ShortLink.create!(original_url: intl_url)
      
      get "/api/v1/decode/#{link.slug}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['original_url']).to eq(intl_url)
    end

    it 'handles encoded short URLs in query param' do
      link = ShortLink.create!(original_url: 'https://example.com')
      short_url = "http://localhost:3000/#{link.slug}"
      
      get "/api/v1/decode?url=#{CGI.escape(short_url)}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['original_url']).to eq('https://example.com')
    end

    it 'handles malformed slugs gracefully' do
      get '/api/v1/decode/invalid-slug-with-special-chars!@#'
      
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Short URL not found')
    end
  end
end