class YoutubeG
  
  # The goal of the classes in this module is to build the request URLs for each type of search
  module Request
    
    class BaseSearch
      attr_reader :url

      def base_url
        "http://gdata.youtube.com/feeds/"                
      end
    end
    
    class UserSearch < BaseSearch
      
      def initialize(params, options={})
        @url = base_url
        return @url << "#{options[:user]}/favorites" if params == :favorites
        @url << "#{params[:user]}/uploads" if params[:user]
      end
      
      def base_url
        super << "users/"
      end
    end
        
    class StandardSearch < BaseSearch
      TYPES = [ :most_viewed, :top_rated, :recently_featured, :watch_on_mobile ]
      TIMES = [ :all_time, :today, :this_week, :this_month ]
      
      def initialize(type, options={})
        if TYPES.include?(type)
          @url = base_url << type.to_s
          @url << "?time=#{options.delete(:time)}" if TIMES.include?(options[:time])
        else
          raise "Invalid type, must be one of: #{ TYPES.each { |t| t.to_s }.join(", ") }"
        end
      end
      
      def base_url
        super << "standardfeeds/"        
      end
    end
    
    class VideoSearch < BaseSearch
      attr_reader :max_results                     # max_results
      attr_reader :order_by                        # orderby, ([relevance], viewCount)
      attr_reader :offset                          # start-index
      attr_reader :query                           # vq
      attr_reader :response_format                 # alt, ([atom], rss, json)
      attr_reader :tags                            # /-/tag1/tag2
      attr_reader :categories                      # /-/Category1/Category2
      attr_reader :video_format                    # format (1=mobile devices)
      
      def initialize(params={})
        return if params.nil?

        @url = base_url
        
        # http://gdata.youtube.com/feeds/videos/T7YazwP8GtY
        return @url << "/" << params[:video_id] if params[:video_id]
        
        @url << "/-/" if (params[:categories] || params[:tags])
        @url << categories_to_params(params.delete(:categories)) if params[:categories]
        @url << tags_to_params(params.delete(:tags)) if params[:tags]

        params.each do |key, value| 
          name = key.to_s
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
        
        @url << build_url(to_youtube_params) if params[:query]  
      end
      
      def base_url
        super << "videos"
      end
      
      def to_youtube_params
        {
          'max-results' => @max_results,
          'orderby' => @order_by,
          'start-index' => @offset,
          'vq' => @query,
          'alt' => @response_format,
          'format' => @video_format
        }
      end
      
      private
        # Convert category symbols into strings and build the URL. GData requires categories to be capitalized. 
        # Categories defined like: categories => { :include => [:news], :exclude => [:sports], :either => [..] }
        # or like: categories => [:news, :sports]
        def categories_to_params(categories)
          if categories.respond_to?(:keys) and categories.respond_to?(:[])
            s = ""
            s << categories[:either].map { |c| c.to_s.capitalize }.join("%7C") << '/' if categories[:either]
            s << categories[:include].map { |c| c.to_s.capitalize }.join("/") << '/' if categories[:include]            
            s << ("-" << categories[:exclude].map { |c| c.to_s.capitalize }.join("/-")) << '/' if categories[:exclude]
            s
          else
            categories.map { |c| c.to_s.capitalize }.join("/") << '/'
          end
        end
        
        # Tags defined like: tags => { :include => [:football], :exclude => [:soccer], :either => [:polo, :tennis] }
        # or tags => [:football, :soccer]
        def tags_to_params(tags)
          if tags.respond_to?(:keys) and tags.respond_to?(:[])
            s = ""
            s << tags[:either].map { |t| CGI.escape(t.to_s) }.join("%7C") << '/' if tags[:either]
            s << tags[:include].map { |t| CGI.escape(t.to_s) }.join("/") << '/' if tags[:include]            
            s << ("-" << tags[:exclude].map { |t| CGI.escape(t.to_s) }.join("/-")) << '/' if tags[:exclude]
            s
          else
            tags.map { |t| CGI.escape(t.to_s) }.join("/") << '/'
          end          
        end

        def build_url(params)
          u = '?'
          item_count = 0
          params.keys.each do |key|
            value = params[key]
            next if value.nil?

            u << '&' if (item_count > 0)
            u << "#{key}=#{CGI.escape(value.to_s)}"
            item_count += 1
          end
          u
        end
        
    end
  end
end
