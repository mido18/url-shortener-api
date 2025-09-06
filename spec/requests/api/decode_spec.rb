require 'swagger_helper'

RSpec.describe 'Decode API', type: :request do
  path '/api/v1/decode/{slug}' do
    get 'Decode URL by slug' do
      tags 'URL Decoding'
      description 'Retrieve original URL from a short link slug'
      produces 'application/json'
      
      parameter name: :slug, in: :path, type: :string, description: '6-character alphanumeric slug', example: 'a00001'

      response '200', 'URL decoded successfully' do
        schema type: :object,
               properties: {
                 original_url: {
                   type: :string,
                   description: 'The original URL',
                   example: 'https://example.com/very/long/path?with=parameters'
                 }
               }

        let(:slug) do
          link = ShortLink.create!(original_url: 'https://example.com')
          link.slug
        end
        run_test!
      end

      response '404', 'Short URL not found' do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: 'Error message',
                   example: 'Short URL not found'
                 }
               }

        let(:slug) { 'nonexistent' }
        run_test!
      end
    end
  end

  path '/api/v1/decode' do
    get 'Decode URL by query parameter' do
      tags 'URL Decoding'
      description 'Decode short URL to get the original URL'
      produces 'application/json'
      
      parameter name: :url, in: :query, type: :string, description: 'Short URL to decode', example: 'http://localhost:3000/a00001'

      response '200', 'Short URL decoded successfully' do
        schema type: :object,
               properties: {
                 original_url: {
                   type: :string,
                   description: 'The original URL',
                   example: 'https://example.com'
                 }
               }

        let(:url) do
          link = ShortLink.create!(original_url: 'https://example.com')
          "http://localhost:3000/#{link.slug}"
        end
        run_test!
      end

      response '404', 'Short URL not found' do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: 'Error message',
                   example: 'Short URL not found'
                 }
               }

        let(:url) { 'http://localhost:3000/nonexistent' }
        run_test!
      end

      response '404', 'Missing parameters' do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: 'Error message',
                   example: 'Short URL not found'
                 }
               }

        let(:url) { nil }
        run_test!
      end
    end
  end

  # Legacy endpoints for backward compatibility
  path '/decode/{slug}' do
    get 'Decode URL by slug (Legacy)' do
      tags 'Legacy Endpoints'
      description 'Retrieve original URL from a short link slug (backward compatibility endpoint)'
      produces 'application/json'
      
      parameter name: :slug, in: :path, type: :string, description: '6-character alphanumeric slug', example: 'a00001'

      response '200', 'URL decoded successfully' do
        schema type: :object,
               properties: {
                 original_url: {
                   type: :string,
                   description: 'The original URL',
                   example: 'https://example.com/very/long/path?with=parameters'
                 }
               }

        let(:slug) do
          link = ShortLink.create!(original_url: 'https://example.com')
          link.slug
        end
        run_test!
      end

      response '404', 'Short URL not found' do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: 'Error message',
                   example: 'Short URL not found'
                 }
               }

        let(:slug) { 'nonexistent' }
        run_test!
      end
    end
  end

  path '/decode' do
    get 'Decode URL by query parameter (Legacy)' do
      tags 'Legacy Endpoints'
      description 'Decode short URL to get the original URL (backward compatibility endpoint)'
      produces 'application/json'
      
      parameter name: :url, in: :query, type: :string, description: 'Short URL to decode', example: 'http://localhost:3000/a00001'

      response '200', 'Short URL decoded successfully' do
        schema type: :object,
               properties: {
                 original_url: {
                   type: :string,
                   description: 'The original URL',
                   example: 'https://example.com'
                 }
               }

        let(:url) do
          link = ShortLink.create!(original_url: 'https://example.com')
          "http://localhost:3000/#{link.slug}"
        end
        run_test!
      end

      response '404', 'Short URL not found' do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: 'Error message',
                   example: 'Short URL not found'
                 }
               }

        let(:url) { 'http://localhost:3000/nonexistent' }
        run_test!
      end
    end
  end
end