require 'rubygems'
require 'net/http'
require 'json'
require 'pry-rescue'
require 'pry-stack_explorer'
require 'pry-debugger'
#require 'ruby-prof'

WIKIBASE = 'http://en.wikipedia.org/w/api.php'
EXCLUDED = ["FULLPAGENAME", "SUBPAGENAME", "Lc", "Lx", "NAMESPACE", "PAGENAME", "DEFAULTSORT", "Documentation",
            "TALKSPACE", "FULLROOTPAGENAME", "SUBJECTSPACE", "BASEPAGENAME", "ROOTPAGENAME", "PENDINGCHANGELEVEL",
            "NAMESPACENUMBER", "FULLPAGENAMEE", "TALKPAGENAME", "</nowiki>", "SUBJECTPAGENAME", "Tl", "Tlx", "♥",
            "Template:FlagIOC"]

class String
  def upfirst
    self[0] = self[0].upcase
    self
  end
end

class WikiPages
  @@pages = []
  def self.add(name, via: :content)
  	w = WikiPage.new(name, via)
    @@pages << w
    w
  end

  def self.pages
    class_variable_get :@@pages
  end

  private

  class WikiPage
    attr_accessor :name, :templates
    
    def initialize(name, via)
      @name = name
      @via = via
      populate
    end

    def name=(page)
      if page != @name
        @name = page
        populate
      end
    end
    
    private
    
    def populate
      if @via == :transclusion
        populate_templates
      else
        populate_content
      end
    end

    def populate_content
      unless @name
        puts "Please set the name first!"
        return
      end

      uri = URI.parse(WIKIBASE)
      params = { format: 'json', action: 'query', prop: 'revisions', rvprop: 'content', titles: "#{URI.encode(@name.gsub(' ', '_'))}" }
      #puts "params: #{params.inspect}"
      uri.query = URI.encode_www_form(params)
      #puts "uri: #{uri}"
      resp = Net::HTTP.get_response(uri)
      data = resp.body
      result = JSON.parse(data)
      content = result['query']['pages'].first[1]['revisions'][0]['*']

      # Clean up content
      content = content.gsub(/< *nowiki *>.*?< *\/nowiki *>/m,'')
      content = content.gsub(/< *noinclude *>.*?< *\/noinclude *>/m,'')
      @templates = content.scan(/{{([^# ][^|}\n]*)/).flatten

      binding.pry if @name == 'History_of_Liberia'
      # Clean up templates
      @templates.reject! {|x| x =~ /:/ }
      @templates.reject! {|x| x =~ /{/ }
      @templates.reject! {|x| x.end_with? '_' }
      binding.pry if @name == 'History_of_Liberia'
      @templates.map! { |x| "Template:#{x.strip.upfirst}" }
      binding.pry if @name == 'History_of_Liberia'
      @templates = @templates.uniq
      binding.pry if @name == 'History_of_Liberia'
      @templates.reject! {|x| x =~ /Template: *{/ }
      binding.pry if @name == 'History_of_Liberia'
      @templates.reject! {|x| EXCLUDED.include? x.gsub(/Template:/, '') }
      binding.pry if @name == 'History_of_Liberia'
      #puts @templates.inspect
    end

    def populate_templates
      unless @name
        puts "Please set the name first!"
        return
      end
      
      uri = URI.parse(WIKIBASE)
      params = { format: 'json', action: 'query', prop: 'templates', tllimit: 100, titles: "#{URI.encode(@name.gsub(' ', '_'))}" }
      puts "params: #{params.inspect}"
      uri.query = URI.encode_www_form(params)
      puts "uri: #{uri}"
      resp = Net::HTTP.get_response(uri)
      data = resp.body
      result = JSON.parse(data)
      @templates = result['query']['pages'].first[1]['templates'].map {|x| x['title'].upfirst}
    end
  end

end
