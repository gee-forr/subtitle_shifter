
# encoding: UTF-8

#@example Manipulate subtitles from the command line
#  $ subtitle_shifter --help
#  $ subtitle_shifter --operation add --index 12 --time 2,345 source.srt dest.srt
#@example Manipulate subtitles from within a ruby program
#  # This will shift all subtitles from index 12 onward by 2.345 seconds
#  # or 2345 milliseconds
#  subs = SubtitleShifter.new('mysubs.srt')
#  subs.parse
#  subs.shift(:index => 12, :time => 2345)
#@example Shift subtitles backward
#  # This will shift subtitles backward, beware - you cannot shift
#  # subtitles backward so that they overlap the preceding subtitles.
#  # A RuntimeError exception will be raised if this occurs.
#  subs.shift(:index => 12, :time => -2345) # Simply provide a negative time value
#@example Output subtitles once they've been parsed and/or manipulated
#  puts subs
#  # -- or --
#  subs.to_s
#@see http://en.wikipedia.org/wiki/Subrip Wikipedia's article on the SubRip format
class SubtitleShifter
  module Version
    MAJOR = 1
    MINOR = 1
    PATCH = 0
    BUILD = 0

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end

  # A boolean flag highlighting whether or not subtitles have been parsed yet
  attr_reader :parsed_ok
  # A hash of the parsed subtitles. You normally wouldn't need to access this directly
  # @example The format of the hash is as follows
  #   {1 => {:start => 107,
  #          :end   => 5762,
  #          :subtitle => 'This is the first subtitle'
  #         },
  #   {2 => {:start => 5890,
  #          :end   => 10553,
  #          :subtitle => 'This is the second subtitle'
  #         }
  # @note I chose to implement internal representation of subtitle files as a hash
  #   and not an array, which would've been more efficient, as subtitles cannot be
  #   guaranteed to start at index 1
  #   That being said, I can already think of a way to do this using an array and offset attribute
  attr_reader :subtitles

  # The delimiter used for separating SubRip time stamps
  TIME_SEPERATOR = '-->'

  # @param [String] file      A string of the file name
  # @param [String] linebreak A string of the linebreak pattern.
  def initialize(file, linebreak = "\r\n")
    @sub_file  = file
    @linebreak = linebreak
    @parsed_ok = false
  end

  # Parses the subtitles
  # @note Always call only after initialising.
  # @note If your subtitle file is UTF-8 encoded, and has a Byte Order Mark as its first few bytes,
  #   the BOM will not be preserved when outputing the parsed and shifted subtitles. You probably don't
  #   need it anyway
  # @example
  #   sub.parse if sub.parsed_ok
  # @see http://en.wikipedia.org/wiki/UTF-8#Byte_order_mark Wikipedia's article on UTF-8 and BOM
  def parse
    raw_text  = File.open(@sub_file, 'r').read.force_encoding('UTF-8')
    raw_text.gsub!("\xEF\xBB\xBF".force_encoding("UTF-8"), '') #Remove stupid BOM that was causing me so much grief!

    #raw_text       = IO.read @sub_file
    subtitle_parts = raw_text.split "#{@linebreak}#{@linebreak}"
    @subtitles     = {}

    subtitle_parts.each do |subtitle|
      @subtitles.update extract_sub_data subtitle
    end

    # No longer needed due to removal of BOM
    #fix_first_index   # What a hack :(
    @parsed_ok = true # Not very useful, but will help when error checking is added
  end

  # Shifts subtitles forward (or backward) by a number of ms from an index
  # @param [Integer] :index The index of the subtitle
  # @param [Integer] :time The time (in ms) by which you wish to shift the subtitles. A negative value will shift backwards.
  # @example
  #   sub.shift(:index => 42, :time => 10000) # Shift subs from index 42 onwards by 10 seconds.
  # @raise [RuntimeError] Raises this exception when shifting backwards if index and index-1 time's overlap
  def shift(args)
    first = args[:index] # used for checking first go round.
    index = first
    shift = args[:time]

    if shift < 0 # backward shift check
      time1 = @subtitles[first][:start] + shift
      time2 = @subtitles[first-1][:end]
      raise RuntimeError, 'Cannot overlap backward shift' if time2 > time1
    end

    loop do
      break unless @subtitles.has_key?(index)

      @subtitles[index][:start] += shift
      @subtitles[index][:end]   += shift

      index += 1
    end
  end

  # Outputs parsed subtitles
  # @raise [RuntimeError] Will raise this exception if an attempt is made to output the subs before parsing has taken place
  # @see SubtitleShifter#parsed_ok
  def to_s
    raise RuntimeError, 'File has not been parsed yet' unless @parsed_ok

    output = ''

    @subtitles.sort.map do |index, sub| 
      start = ms_to_srt_time sub[:start]
      fin   = ms_to_srt_time sub[:end]

      output += "#{index}#{@linebreak}#{start} #{TIME_SEPERATOR} #{fin}#{@linebreak}#{sub[:subtitle]}#{@linebreak}#{@linebreak}"
    end

    output.chomp
  end

  private

  def extract_sub_data(subtitle)
    s     = subtitle.split @linebreak
    times = s[1].split " #{TIME_SEPERATOR} "

    {s[0].to_i => {
      start:    srt_time_to_ms(times[0]),
      end:      srt_time_to_ms(times[1]),
      subtitle: s[2..-1].join(@linebreak)
      }
    }
  end

  def srt_time_to_ms(srt_time)
    time_parts = parse_srt_time srt_time

    hours_ms = time_parts[:hours] * 60 * 60 * 1000
    mins_ms  = time_parts[:mins]  * 60 * 1000
    secs_ms  = time_parts[:secs]  * 1000

    hours_ms + mins_ms + secs_ms + time_parts[:ms]
  end

  def ms_to_srt_time(ms)
    hours   = (ms / (1000 * 60 *60)) % 60
    minutes = (ms / (1000 * 60))     % 60
    seconds = (ms / 1000)            % 60
    adj_ms  = ms.to_s[-3..-1].to_i

    "%02d:%02d:%02d,%03d" % [hours, minutes, seconds, adj_ms]
  end

  def parse_srt_time (srt_time)
    # Time looks like: hh:mm:ss,ms
    #              ... 10:09:08,756
    /^(\d+):(\d+):(\d+),(\d+)$/ =~ srt_time

    {hours: $1.to_i,
     mins:  $2.to_i,
     secs:  $3.to_i,
     ms:    $4.to_i
    }
  end

  # No longer needed due to fixing the BOM issue. But I'm leaving it in.
  def fix_first_index
    # This makes me feel *so* dirty :/
    sub_arr = @subtitles.to_a
    idx1    = sub_arr[0][0]
    idx2    = sub_arr[1][0]

    @subtitles[idx2 - 1] = @subtitles.delete idx1 # At least I learnt this trick :) How to rename a hash key
  end
end
