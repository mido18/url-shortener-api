class ShortLink < ApplicationRecord
  validates :original_url, presence: true
  validates :slug, uniqueness: true, allow_nil: true

  before_create :generate_slug

  def full_short_url(request)
    "#{request.base_url}/#{slug}"
  end

  def self.find_or_create_by_url(url)
    # Check cache first
    slug = Rails.cache.read("url:#{url}")
    return find_by(slug: slug) if slug

    # Check if URL already exists in database
    existing_link = find_by(original_url: url)
    if existing_link
      cache_link_mapping(existing_link)
      return existing_link
    end

    # Create new short link
    link = new(original_url: url)
    if link.save
      cache_link_mapping(link)
    end
    link
  end

  def self.find_by_slug(slug)
    # Check cache first
    original_url = Rails.cache.read("slug:#{slug}")
    return original_url if original_url.present?

    # Fallback to database
    link = find_by(slug: slug)
    if link
      cache_link_mapping(link)
      return link.original_url
    end
    nil
  end

  def self.find_by_url(url)
    # Only decode short URLs, extract slug and decode
    if url.match?(/^https?:\/\/[^\/]+\/([a-zA-Z0-9]+)$/)
      slug = url.split('/').last
      return find_by_slug(slug)
    end
    # Not a short URL format
    nil
  end

  private

  def self.cache_link_mapping(link)
    Rails.cache.write("url:#{link.original_url}", link.slug)
    Rails.cache.write("slug:#{link.slug}", link.original_url)
  end

  def generate_slug
    return if slug.present?
    next_id = get_next_id
    # Offset to start from 'a00000' in Base62 (10 * 62^5)
    offset_id = next_id + 9_161_328_320
    self.slug = Base62.encode(offset_id)
  end

  def get_next_id
    Rails.cache.increment("url_counter", 1, initial: 1) || fallback_counter_increment
  end

  def fallback_counter_increment
    current = Rails.cache.read("url_counter") || 0
    next_val = current + 1
    Rails.cache.write("url_counter", next_val)
    next_val
  end
end
