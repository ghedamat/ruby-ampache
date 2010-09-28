require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'digest/sha2'

require File.join(File.dirname(__FILE__),'lib-ampache')

=begin
Class is initialized with Hostname, user and password
An auth token is requested on class initialization

To get the artist list from database you can 
call the method artists(nil) and you'll get an array
of AmpacheArtists. 

To get albums from an artist you can issue
artist_instance.albums or ampache_ruby.instance.albums(artist_instance)
=end
class AmpacheRuby
    
    
    def initialize(host,user,psw)
        uri = URI.parse(host)
        @host = uri.host
        @path = uri.path
        @user = user
        @psw = psw
        @token = nil
        @token = getAuthToken(user,psw)
    end

    attr_accessor :host, :path, :user, :psw, :token, :playlist
    
    # tryies to obtain an auth token 
    def getAuthToken(user,psw)
        action= "handshake"
        # auth string
        key =  Digest::SHA2.new << psw 
        time = Time.now.to_i.to_s
        psk = Digest::SHA2.new << (time + key.to_s)

        args = { 'auth' => psk, 'timestamp'=> time, 'version' => '350001', 'user' => user}
        doc = callApiMethod(action,args);

        return doc.at("auth").content
    end
    
    # generic api method call
    def callApiMethod( method, args={})
        args['auth'] ||= token if token
        url = path + "/server/xml.server.php?action=#{method}&#{args.keys.collect { |k| "#{k}=#{args[k]}"}.join('&')}" 
        response = Net::HTTP.get_response(host,url )
        return Nokogiri::XML(response.body)
    end

    # retrive artists lists from database,
    # name is an optional filter
    def artists(name = nil)
        args = {}
        args = { 'filter' => name.to_s } if name  # artist search 
        artists = []
        doc = callApiMethod("artists",args)
        doc.xpath("//artist").each do |a|
            artists << AmpacheArtist.new(self,a['id'] ,a.at("name").content)
        end
        return artists
    end

    def albums(artist)
        albums = []
        args = { 'filter' => artist.uid.to_s }
        doc = callApiMethod("artist_albums",args)
        doc.xpath("//album").each do |a|
            albums  << AmpacheAlbum.new(self,a['id'], a.at("name").content, artist)
        end
        return albums
    end

    def songs(album)
        songs = []
        args = { 'filter' => album.uid.to_s }
        doc = callApiMethod("album_songs",args)
        doc.xpath("//song").each do |s|
            songs << AmpacheSong.new(self,s['id'], s.at("title").content, album.artist, album, s.at("url").content)
        end
        return songs
    end
    
end

