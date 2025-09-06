require 'rails_helper'

RSpec.describe ShortLink, type: :model do
  describe 'validations' do
    it 'validates presence of original_url' do
      link = ShortLink.new(original_url: nil)
      expect(link).not_to be_valid
      expect(link.errors[:original_url]).to include("can't be blank")
    end

    it 'validates uniqueness of slug' do
      ShortLink.create!(original_url: 'https://example.com', slug: 'test')
      link = ShortLink.new(original_url: 'https://other.com', slug: 'test')
      expect(link).not_to be_valid
      expect(link.errors[:slug]).to include('has already been taken')
    end
  end

  describe '#generate_slug' do
    it 'generates a 6-character alphanumeric slug before creation' do
      link = ShortLink.create!(original_url: 'https://example.com')
      expect(link.slug).to be_present
      expect(link.slug).to match(/\A[a-zA-Z0-9]{6}\z/)
      expect(link.slug.length).to eq(6)
    end

    it 'generates sequential slugs starting with "a"' do
      link1 = ShortLink.create!(original_url: 'https://example1.com')
      link2 = ShortLink.create!(original_url: 'https://example2.com')
      
      expect(link1.slug).to match(/\Aa[0-9a-zA-Z]{5}\z/)
      expect(link2.slug).to match(/\Aa[0-9a-zA-Z]{5}\z/)
      expect(link1.slug).not_to eq(link2.slug)
    end

    it 'does not override existing slug' do
      link = ShortLink.create!(original_url: 'https://example.com', slug: 'custom')
      expect(link.slug).to eq('custom')
    end
  end

  describe '#full_short_url' do
    it 'returns full short URL with 6-character alphanumeric slug' do
      link = ShortLink.create!(original_url: 'https://example.com')
      request = double(base_url: 'http://localhost:3000')
      
      expect(link.full_short_url(request)).to eq("http://localhost:3000/#{link.slug}")
      expect(link.full_short_url(request)).to match(/http:\/\/localhost:3000\/[a-zA-Z0-9]{6}/)
    end
  end

  describe '.find_or_create_by_url' do
    before { Rails.cache.clear }

    it 'creates new link if not cached' do
      url = 'https://example1.com'
      expect { ShortLink.find_or_create_by_url(url) }.to change(ShortLink, :count).by(1)
    end

    it 'returns cached link if exists' do
      url = 'https://example2.com'
      link = ShortLink.create!(original_url: url)
      Rails.cache.write("url:#{url}", link.slug)
      
      result = ShortLink.find_or_create_by_url(url)
      expect(result).to eq(link)
    end

    it 'caches the link after creation' do
      url = 'https://example3.com'
      link = ShortLink.find_or_create_by_url(url)
      expect(Rails.cache.read("url:#{url}")).to eq(link.slug)
      expect(Rails.cache.read("slug:#{link.slug}")).to eq(url)
    end

    it 'returns existing database record without creating duplicate' do
      url = 'https://example4.com'
      existing_link = ShortLink.create!(original_url: url)
      
      expect {
        result = ShortLink.find_or_create_by_url(url)
        expect(result).to eq(existing_link)
      }.not_to change(ShortLink, :count)
    end

    it 'handles invalid URLs gracefully' do
      link = ShortLink.find_or_create_by_url('')
      expect(link).not_to be_persisted
      expect(link.errors[:original_url]).to include("can't be blank")
    end
  end

  describe '.find_by_slug' do
    before { Rails.cache.clear }

    it 'returns original_url for existing slug' do
      link = ShortLink.create!(original_url: 'https://example.com')
      result = ShortLink.find_by_slug(link.slug)
      expect(result).to eq(link.original_url)
    end

    it 'returns cached result if available' do
      Rails.cache.write('slug:test123', 'https://cached.com')
      result = ShortLink.find_by_slug('test123')
      expect(result).to eq('https://cached.com')
    end

    it 'returns nil for non-existent slug' do
      result = ShortLink.find_by_slug('nonexistent')
      expect(result).to be_nil
    end

    it 'caches result after database lookup' do
      link = ShortLink.create!(original_url: 'https://example.com')
      ShortLink.find_by_slug(link.slug)
      
      expect(Rails.cache.read("slug:#{link.slug}")).to eq(link.original_url)
      expect(Rails.cache.read("url:#{link.original_url}")).to eq(link.slug)
    end
  end

  describe '.find_by_url' do
    before { Rails.cache.clear }

    it 'decodes short URLs by extracting slug' do
      link = ShortLink.create!(original_url: 'https://example.com')
      short_url = "http://localhost:3000/#{link.slug}"
      
      result = ShortLink.find_by_url(short_url)
      expect(result).to eq('https://example.com')
    end

    it 'handles short URLs from different domains' do
      link = ShortLink.create!(original_url: 'https://example.com')
      short_url = "https://short.ly/#{link.slug}"
      
      result = ShortLink.find_by_url(short_url)
      expect(result).to eq('https://example.com')
    end

    it 'returns nil for non-existent short URL slug' do
      short_url = "http://localhost:3000/nonexistent"
      result = ShortLink.find_by_url(short_url)
      expect(result).to be_nil
    end

    it 'returns nil for original URLs (not short URLs)' do
      ShortLink.create!(original_url: 'https://example.com')
      result = ShortLink.find_by_url('https://example.com')
      expect(result).to be_nil
    end
  end

  describe 'edge cases' do
    before { Rails.cache.clear }

    it 'handles very long URLs' do
      long_url = 'https://example.com/' + 'a' * 2000
      link = ShortLink.create!(original_url: long_url)
      expect(link.slug).to be_present
      expect(link.original_url).to eq(long_url)
    end

    it 'handles URLs with special characters' do
      special_url = 'https://example.com/path?q=hello%20world&foo=bar#section'
      link = ShortLink.create!(original_url: special_url)
      expect(link.slug).to be_present
      expect(link.original_url).to eq(special_url)
    end

    it 'handles international domain names' do
      intl_url = 'https://münchen.de'
      link = ShortLink.create!(original_url: intl_url)
      expect(link.slug).to be_present
      expect(link.original_url).to eq(intl_url)
    end

    it 'generates unique sequential slugs' do
      link1 = ShortLink.create!(original_url: 'https://example1.com')
      link2 = ShortLink.create!(original_url: 'https://example2.com')
      
      expect(link1.slug).to match(/\A[a-zA-Z0-9]{6}\z/)
      expect(link2.slug).to match(/\A[a-zA-Z0-9]{6}\z/)
      expect(link1.slug).not_to eq(link2.slug)
    end

    it 'handles concurrent slug generation' do
      threads = []
      results = []
      
      5.times do |i|
        threads << Thread.new do
          link = ShortLink.create!(original_url: "https://concurrent#{i}.com")
          results << link.slug
        end
      end
      
      threads.each(&:join)
      expect(results.uniq.length).to eq(5) # All slugs should be unique
    end

    it 'handles nil and empty cache values' do
      Rails.cache.write('slug:empty', '')
      Rails.cache.write('slug:nil', nil)
      
      expect(ShortLink.find_by_slug('empty')).to be_nil
      expect(ShortLink.find_by_slug('nil')).to be_nil
    end

    it 'handles cache misses gracefully' do
      # Simulate cache being cleared between operations
      link = ShortLink.create!(original_url: 'https://example.com')
      Rails.cache.clear
      
      result = ShortLink.find_by_slug(link.slug)
      expect(result).to eq(link.original_url)
    end
  end
end
