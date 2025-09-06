require 'swagger_helper'

RSpec.describe 'Encode API', type: :request do
  path '/api/v1/encode' do
    post 'Create short URL' do
      tags 'URL Shortening'
      description 'Convert a long URL into a short, shareable link'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :url_data, in: :body, schema: {
        type: :object,
        properties: {
          url: {
            type: :string,
            description: 'The URL to be shortened',
            example: 'https://example.com/very/long/path?with=parameters'
          }
        },
        required: ['url']
      }

      response '200', 'URL shortened successfully' do
        schema type: :object,
               properties: {
                 short_url: {
                   type: :string,
                   description: 'The shortened URL with 6-character alphanumeric slug',
                   example: 'http://localhost:3000/a00001'
                 }
               }

        let(:url_data) { { url: 'https://example.com' } }
        
        before do
          Rails.cache.clear
        end
        
        run_test!
      end

      response '422', 'Validation error' do
        schema type: :object,
               properties: {
                 error: {
                   type: :array,
                   items: { type: :string },
                   description: 'Validation error messages',
                   example: ["Original url can't be blank"]
                 }
               }

        let(:url_data) { { url: '' } }
        run_test!
      end
    end
  end

  # Legacy endpoint for backward compatibility
  path '/encode' do
    post 'Create short URL (Legacy)' do
      tags 'Legacy Endpoints'
      description 'Convert a long URL into a short, shareable link (backward compatibility endpoint)'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :url_data, in: :body, schema: {
        type: :object,
        properties: {
          url: {
            type: :string,
            description: 'The URL to be shortened',
            example: 'https://example.com/very/long/path?with=parameters'
          }
        },
        required: ['url']
      }

      response '200', 'URL shortened successfully' do
        schema type: :object,
               properties: {
                 short_url: {
                   type: :string,
                   description: 'The shortened URL with 6-character alphanumeric slug',
                   example: 'http://localhost:3000/a00001'
                 }
               }

        let(:url_data) { { url: 'https://example.com' } }
        
        before do
          Rails.cache.clear
        end
        
        run_test!
      end

      response '422', 'Validation error' do
        schema type: :object,
               properties: {
                 error: {
                   type: :array,
                   items: { type: :string },
                   description: 'Validation error messages',
                   example: ["Original url can't be blank"]
                 }
               }

        let(:url_data) { { url: '' } }
        run_test!
      end
    end
  end
end