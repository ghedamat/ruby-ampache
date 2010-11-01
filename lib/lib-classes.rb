require 'open4'
require 'timeout'
class AmpacheArtist
    
    # include play module
    def initialize(ar,uid,name)
        @ar = ar
        @uid = uid
        @name = name
    end

    attr_reader :uid, :name

    def albums
        @albums ||= @ar.albums(self)
    end
end


class AmpacheAlbum
    
    def initialize(ar,uid,name,artist)
        @ar = ar
        @uid = uid
        @name = name
        @artist = artist
    end

    attr_reader :uid, :name, :artist

    def songs
        @songs ||= @ar.songs(self)
    end

    def addToPlaylist(pl)
        songs.each do |s|
            s.addToPlaylist(pl)
        end
    end

end

class AmpacheSong

    def initialize(ar,uid,title,artist,album, url) 
        @ar = ar
        @uid = uid
        @title = title
        @artist = artist
        @album = album
        @url = url
    end

    attr_reader :uid, :title, :artist, :album, :url

    def addToPlaylist(pl)
        pl.add(self)
    end

end

class AmpachePlaylist 
    def add(song)
        if !@pid
            $options[:path] ||= '/usr/bin/mplayer'
            mplayer_options = "-slave -quiet"
            mplayer = "#{$options[:path]} #{mplayer_options} \"#{song.url}\""
            @pid,@stdin,@stdout,@stderr = Open4.popen4(mplayer)
            begin
                t = Timeout::timeout(3) do 
                    until @stdout.gets.inspect =~ /playback/ do
                    end
                end
            rescue Timeout::Error   
                puts "err on reading data"
            end
        else
            begin
                @stdin.puts "loadfile \"#{song.url}\" 1"
            rescue Errno::EPIPE
                #puts "playlist is over" 
                @pid = nil
                add(song)
             end
        end
    end

    def play
        @player.play if @pid 
    end

    def stop
        begin
            @stdin.puts "quit" if @pid
        rescue Errno::EPIPE
            puts "playlist is over" 
        end
        @pid = nil
    end

    def pause
        begin
            @stdin.puts "pause" if @pid
        rescue Errno::EPIPE
            puts "playlist is over" 
        end
    end

    def next
        begin
            @stdin.puts "pt_step 1 1" if @pid
        rescue Errno::EPIPE
            puts "playlist is over" 
            @pid = nil
        end
    end
    
    def nowPlaying
        return "Not playing man!" unless @pid
        begin
            s= ''
            @tim = 0
            begin
                t = Timeout::timeout(3) do 
                    #s+= get("file_name") 
                    s+= get("meta_title")  
                    s+= get("meta_artist")  
                    s+= get("meta_album")  
                    s.chomp!
                end
                @tim = 0
                return s
            rescue Timeout::Error
                @tim += 1
                if (@tim > 3 )
                    @tim = 0
                    return "err" 
                else
                    return nowPlaying 
                end
            end
        rescue Errno::EPIPE
            return "playlist is over" 
            @pid = nil
        end
    end
    
    # I borrowed these two method from the author of mplayer-ruby!
    # so my thanks to Artuh Chiu and his great gem mplayer-ruby
    def get(value)
      field = value.to_s
      match = case field
      when "time_pos" then "ANS_TIME_POSITION"
      when "time_length" then "ANS_LENGTH"
      when "file_name" then "ANS_FILENAME"
      else "ANS_#{field.upcase}"
      end
      res = command("get_#{value}",/#{match}/)
      res.gsub("#{match}=","").gsub("'","")
    end

    def command(cmd,match = //)
      @stdin.puts(cmd)
      response = ""
      until response =~ match
        response = @stdout.gets
#XXX escaping bad utf8 chars
        ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
        response =ic.iconv(response + ' ')[0..-2]
      end
      response.gsub("\e[A\r\e[K","")
    end

end

