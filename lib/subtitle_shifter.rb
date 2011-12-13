
# encoding: UTF-8

class SubtitleShifter
  module Version
    MAJOR = 1
    MINOR = 0
    PATCH = 0
    BUILD = 0

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end

  attr_reader :subtitles, :parsed_ok

  TIME_SEPERATOR = '-->'

  def initialize(file, linebreak = "\r\n")
    @sub_file  = file
    @linebreak = linebreak
  end

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
