module MemcachesPage
  extend ActiveSupport::Concern
  module ClassMethods
    def memcaches_page(*actions)
      return unless perform_caching
      options = actions.extract_options!

      after_filter({:only => actions}.merge(options)) do |c|
        c.memcache_page(options)
      end
    end

    def memcache_page(content, path, options={})
      return unless perform_caching
      Rails.cache.write path.gsub('%', '%25'), content, options.merge(raw: true)
    end
  end

  def memcache_page(options = {})
    return unless self.class.perform_caching && caching_allowed? && !request.params.key?('no-cache')

    prepend_body = []
    body = (options[:compress] == true) ? ActiveSupport::Gzip.compress(response.body) : response.body

    if options[:enhanced_module] == true
      prepend_body << "EXTRACT_HEADERS"
      prepend_body << "Content-Type: #{response.content_type}; charset=utf-8"
      if options[:compress] == true
        prepend_body << "Content-Encoding: gzip"
      end
      prepend_body << "\r\n"
    end

    self.class.memcache_page(prepend_body.join("\r\n") + body, request.fullpath, options)
  end
end
