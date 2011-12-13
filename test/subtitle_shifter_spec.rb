#!/usr/bin/env ruby
# encoding: UTF-8

require 'minitest/spec'
require 'minitest/autorun'

require './lib/subtitle_shifter'

describe SubtitleShifter do
  it "should have a new method" do
    SubtitleShifter.must_respond_to('new')
  end

  describe "parsing a subtitle file" do
    srt = SubtitleShifter.new('./test/The.Big.Bang.Theory.srt')
    srt.parse

    it "should work with utf-8 files" do
      srt.parsed_ok.must_equal true
    end

    it "should have some parsed data" do
      first_sub = srt.subtitles[46]
      first_sub.must_be_instance_of Hash

      first_sub[:subtitle].must_equal  "♪ Our whole universe\r\nwas in a hot, dense state ♪"
      first_sub[:start].must_equal     173610
      first_sub[:end].must_equal       177196
    end
  end

  describe "shifting subtitles" do
    before(:each) do
      @srt = SubtitleShifter.new('./test/The.Big.Bang.Theory.srt')
      @srt.parse
    end

    describe "forward" do
      it "should shift subtitles forward from an index" do
        @srt.must_respond_to('shift')

        shift = 2500
        start = @srt.subtitles[50][:start]
        fin   = @srt.subtitles[50][:end]

        @srt.shift(:index => 50, :time => shift)
        @srt.subtitles[50][:start].must_equal start+shift
        @srt.subtitles[50][:end].must_equal   fin+shift
      end

      it "should affect all indexes till the end" do
        # start = @srt
        # 53 - s - 191962 e - 192710
        @srt.shift(:index => 50, :time => 2500)
        @srt.subtitles[53][:start].must_equal 194462
        @srt.subtitles[53][:end].must_equal   195210
      end
    end

    describe "backward" do
      it "should shift subtitles backward from an index" do
        # Test start of shift
        @srt.shift(:index => 50, :time => -1)
        @srt.subtitles[50][:start].must_equal 184737
        @srt.subtitles[50][:end].must_equal   187371
      end

      it "should affect all indexes till the end" do
        # start = @srt
        # 53 - s - 191962 e - 192710
        @srt.shift(:index => 50, :time => -1)
        @srt.subtitles[53][:start].must_equal 191961
        @srt.subtitles[53][:end].must_equal   192709
      end

      it "should raise an exception if shifted too far back" do
        proc do
          @srt.shift(:index => 50, :time => -2500)
        end.must_raise RuntimeError
      end
    end
  end

  describe "outputting an srt file" do
    before(:each) do
      @srt = SubtitleShifter.new('./test/The.Big.Bang.Theory.srt')
    end

    it "should raise an exception if it hasn't been parsed yet" do
      proc do
        @srt.to_s
      end.must_raise RuntimeError
    end

    it "should provide a string that is similar to the file when no shifting takes place" do
      @srt.parse
      @srt.to_s.must_equal "46\r\n00:02:53,610 --> 00:02:57,196\r\n♪ Our whole universe\r\nwas in a hot, dense state ♪\r\n\r\n47\r\n00:02:57,198 --> 00:03:00,532\r\n♪ Then nearly 14 billion years\r\nago expansion started... Wait! ♪\r\n\r\n48\r\n00:03:00,534 --> 00:03:02,184\r\n♪ The Earth began to cool ♪\r\n\r\n49\r\n00:03:02,186 --> 00:03:04,736\r\n♪ The autotrophs began to drool,\r\nNeanderthals developed tools ♪\r\n\r\n50\r\n00:03:04,738 --> 00:03:07,372\r\n♪ We built the Wall ♪\r\n♪ <i>We built the pyramids</i> ♪\r\n\r\n51\r\n00:03:07,374 --> 00:03:10,058\r\n♪ Math, Science, History,\r\nunraveling the mystery ♪\r\n\r\n52\r\n00:03:10,060 --> 00:03:11,960\r\n♪ That all started\r\nwith a big bang ♪\r\n\r\n53\r\n00:03:11,962 --> 00:03:12,710\r\n♪ <i>Bang!</i> ♪\r\n"
    end

    it "should provide a string that shows shifted times when a shift op occurs" do
      @srt.parse
      @srt.shift(:index => 50, :time => 2500)
      @srt.to_s.must_equal "46\r\n00:02:53,610 --> 00:02:57,196\r\n♪ Our whole universe\r\nwas in a hot, dense state ♪\r\n\r\n47\r\n00:02:57,198 --> 00:03:00,532\r\n♪ Then nearly 14 billion years\r\nago expansion started... Wait! ♪\r\n\r\n48\r\n00:03:00,534 --> 00:03:02,184\r\n♪ The Earth began to cool ♪\r\n\r\n49\r\n00:03:02,186 --> 00:03:04,736\r\n♪ The autotrophs began to drool,\r\nNeanderthals developed tools ♪\r\n\r\n50\r\n00:03:07,238 --> 00:03:09,872\r\n♪ We built the Wall ♪\r\n♪ <i>We built the pyramids</i> ♪\r\n\r\n51\r\n00:03:09,874 --> 00:03:12,558\r\n♪ Math, Science, History,\r\nunraveling the mystery ♪\r\n\r\n52\r\n00:03:12,560 --> 00:03:14,460\r\n♪ That all started\r\nwith a big bang ♪\r\n\r\n53\r\n00:03:14,462 --> 00:03:15,210\r\n♪ <i>Bang!</i> ♪\r\n"
    end
  end
end
