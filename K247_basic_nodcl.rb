# 2016-06-04: create for tmsserv ( no numru, dcl, gphys)

#index@2016-06-04
##  General methods
##  Array



##  General methods
  # begin & end process
  # 2014-11-28: Create
  class K247_Main_Watch
    # access
    attr_accessor :begin_time

    def initialize()
      print "Program ", $0, " Start \n\n"
      @begin_time = Time.now
    end # def initialize()
    
    def show_time()
      print "elapsed time = #{(Time.now) - @begin_time}sec\n"
    end # def show_elapsed()
    
    def end_process()
      end_time = Time.now
      print "\n\n"
      print "Program End : #{end_time - @begin_time}sec\n"
    end # def end_process
    
  end # class K247_Main_Watch

  # ToDo: improve @ 2015-09-29
  def exec_command( cmd )
    #print "\n"
    ret = system(cmd)
    puts "ruby info: ret = #{ret}\n  #{cmd}"
    #print "\n\n"
  end

  def exe_with_log( cmd_org, log_fname )
    exe_with_log_fg( cmd_org, log_fname )
  end

  def exe_with_log_fg( cmd_org, log_fname )
    cmd_str = "#{cmd_org} 2>&1 | tee -a #{log_fname}" # foreground
    exe_with_log_common( cmd_str, log_fname )
  end

  def exe_with_log_bg( cmd_org, log_fname )
    cmd_str = "#{cmd_org} >> #{log_fname} 2>&1 &" # background
    exe_with_log_common( cmd_str, log_fname )
  end
    
  def exe_with_log_common( cmd_str, log_fname )
    system( "echo \"command: #{cmd_str}\n\n\" > #{log_fname}" )
    puts "ruby info: #{cmd_str}"
    ret = system( cmd_str )
    puts "ruby info: ret = #{ret}, logfile = #{log_fname}"
  end
    
  # ToDo: improve @ 2015-09-29
  def get_y_or_n( question=nil )
    print question
    answer = gets.chomp
    while (answer != "y") && (answer != "n")
      print "  please answer by y or n: "
      answer = gets.chomp
    end
    return answer
  end

  # ToDo: require ?
  def popen3_wrap( cmd )
    require "open3"

    puts "popen3: #{cmd}"
    o_str = Array(1); e_str = Array(1)
    Open3.popen3( cmd ) do | stdin, stdout, stderr, wait_thread|
      stdout.each_with_index do |line,n| o_str[n] = line end
      stderr.each_with_index do |line,n| e_str[n] = line end
    end
    ret = {"key_meaning"=>"i: stdin, o: stdout, e: stderr, w: wait_thread"}
      ret["o"] = o_str; ret["e"] = e_str
    return ret
  end

    def show_stdoe( p3w_ret )
      puts "  STDOUT:"
        p3w_ret["o"].each do |line| puts "  #{line}" end
      puts "  STDERR:"
        p3w_ret["e"].each do |line| puts "  #{line}" end
    end

  def exit_with_msg( msg )
    print "\n\n!ERROR! #{msg}!\n\nexit\n\n"
    exit -1
  end


  # 2015-10-01: http://qiita.com/khotta/items/9233a9ffeae68b58d84f
  # ToDo : 
  #   - generalize
  #   - rename
  #   - yet : http://melborne.github.io/2010/11/07/Ruby-ANSI/
  def puts_color( msg, color=nil )
    color_set( color ); puts msg; color_end
  end
  def color_set( color=nil )
    case color
      when "red"
        print "\e[31m"
      when "green"
        print "\e[32m"
      when "yellow"
        print "\e[33m"
      when "blue"
        print "\e[34m"
      when nil
        print "please set color\n"
      else
        print "sorry, the color is not yet implemented\n"
    end
  end
  def color_end
    print "\e[0m"
  end

=begin # test_color.rb
require "~/lib_k247/K247_basic"

puts "Hello!"
puts_color "Hello!", "red"
puts_color "Hello!", "green"
puts_color "Hello!"
puts_color "Hello!", "yellow"
puts "Hello!"
=end # test_color.rb
  
  def time_now_str_sec
    return Time.now.strftime("%Y%m%d_%H%M_%S")
  end
##  END: General methods




## Array

def ary_get_include_index( ary, kwd )
  idx = []
  for i in 0..ary.length-1
    idx.push( i ) if ary[i].include?( kwd )
  end
  return idx
end

## END: Array
