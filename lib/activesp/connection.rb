require 'savon'
require 'net/ntlm_http'

Savon::Request.logger.level = Logger::ERROR

module ActiveSP
  
  class Connection
    
    include Util
    
    # TODO: create profile
    attr_reader :login, :password
    
    def initialize(options = {})
      @root_url = options.delete(:root) or raise ArgumentError, "missing :root option"
      @login = options.delete(:login)
      @password = options.delete(:password)
      options.empty? or raise ArgumentError, "unknown options #{options.keys.map { |k| k.inspect }.join(", ")}"
    end
    
    def find_by_key(key)
      type, trail = decode_key(key)
      case type[0]
      when ?S
        ActiveSP::Site.new(self, trail[0], trail[1].to_i)
      when ?L
        ActiveSP::List.new(find_by_key(trail[0]), trail[1])
      when ?F
        parent = find_by_key(trail[0])
        if ActiveSP::Folder === parent
          ActiveSP::Folder.new(parent.list, trail[1], parent)
        else
          ActiveSP::Folder.new(parent, trail[1], nil)
        end
      when ?I
        parent = find_by_key(trail[0])
        if ActiveSP::Folder === parent
          p([parent, parent.list, trail[1]])
          ActiveSP::Item.new(parent.list, trail[1], parent)
        else
          ActiveSP::Item.new(parent, trail[1], nil)
        end
      else
        raise "not yet #{key.inspect}"
      end
    end
    
    def fetch(url)
      # TODO: support HTTPS too
      @open_params ||= begin
        u = URL(@root_url)
        [u.host, u.port]
      end
      Net::HTTP.start(*@open_params) do |http|
        request = Net::HTTP::Get.new(URL(url).full_path.gsub(/ /, "%20"))
        request.ntlm_auth(@login, @password)
        response = http.request(request)
        response
      end
    end
    
  end
  
end