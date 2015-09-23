#!/usr/bin/ruby
# 2015-09-18~: create
require "open3"
# ref: http://qiita.com/tyabe/items/56c9fa81ca89088c5627

# ToDo
#   - make module for duplicate method with git_commit_interactive
#   - master IO object@2015-09-17
#   - master git branch

# history
#   - ~/work/gitauto_K247/git_k247.rb @ 2015-09-23



module Git_K247
# index (ver. 2015-09-23)
#  popen3_wrap( cmd )
#    show_stdoe
#  get_y_or_n
#  git_push_interactive
#  git_pull_interactive
#  git_add_interactive
#  git_commit_interactive
#    exec_command
#  get_gitdirs
#  git_gdir_each

# common part
  # 2015-09-18: create
  # under construction
  def popen3_wrap( cmd )
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


  # 2015-09-18: create
  # tmp method
  def get_y_or_n( question=nil )
    print question
    answer = gets.chomp
    while (answer != "y") && (answer != "n")
      print "  please answer by y or n: "
      answer = gets.chomp
    end
    return answer
  end

# End: common part



def git_push_interactive( arg = nil )

  gstat = popen3_wrap("git remote show origin")
  show_stdoe( gstat )
  ff_kword = "fast-forwardable"
  ud_kword = "up to date"
  gst_push_state = gstat["o"][gstat["o"].length-1]
  if gst_push_state.include?( ff_kword )
    answer = get_y_or_n( "git push? (answer y/n): " )
    if answer == "y"
      ret = popen3_wrap("git push -v origin master:master")
      show_stdoe( ret ); print "\n\n\n"
    else # if answer == "y"
      puts "  you choose not to git push"; print "\n\n\n"
    end # if answer == "y"
  elsif gst_push_state.include?( ud_kword )
    puts "\n\nno need to git push"; print "\n\n\n"
  else
    puts "!CATUTION! something wrong happend!(see above)"
    return -1
  end # if gst_push_state.include?( ff_kword )

  return 0
end # def git_push_interactive( arg = nil )



def git_pull_interactive( arg = nil )

  gstat = popen3_wrap("git remote show origin")
  show_stdoe( gstat )
  od_kword = "local out of date"
  ud_kword = "up to date"
  gst_push_state = gstat["o"][gstat["o"].length-1]
  if gst_push_state.include?( od_kword )
    answer = get_y_or_n( "git pull? (answer y/n): " )
    if answer == "y"
      ret = popen3_wrap("git pull")
      show_stdoe( ret ); print "\n\n\n"
    else # if answer == "y"
      puts "  you choose not to git push"; print "\n\n\n"
    end # if answer == "y"
  elsif gst_push_state.include?( ud_kword )
    puts "\n\nno need to git pull"; print "\n\n\n"
  else
    puts "!CATUTION! something wrong happend!(see above)"
    return -1
  end # if gst_push_state.include?( od_kword )

  return 0
end # def git_pull_interactive( arg = nil )



def git_add_interactive
  exec_command( "git add --interactive" )
end # def git_add_interactive

def git_commit_interactive
  exec_command( "git commit --interactive" )
end # def git_commit_interactive

  def exec_command( cmd )
    puts cmd
    ret = system(cmd)
    puts "[end]#{cmd}: #{ret}"
    print "\n\n"
  end


def get_gitdirs 
  current_dir = Dir.pwd
  home = ENV['HOME']

  gdfile = "#{home}/git_dir_k247.txt"
  gitdirs = Array.new(1)
  open( gdfile, "r").each_with_index{ | line, n |
    gitdirs[n] = line.chomp
  }
  return gitdirs
end # def get_gitdirs 


def git_gdir_each( arg=nil )
  if arg == "pull" || arg == "push"
    gact = arg
  else
    gact = "pull"
    puts "Wrong argument #{arg}, set git action pull"
  end

  gitdirs = get_gitdirs
    gret = Array( gitdirs.length )
  gitdirs.each_with_index do | gdir,n |
    ret = Dir::chdir( gdir )
    puts "Current dir: #{Dir::getwd}"
    unless File::exist?(".git")
      puts "!Caution! This directory is not registered on git!"
      gret[n] = -1
    else
      if gact == "pull"
        gret[n] = git_pull_interactive
      else # "push"
        git_commit_interactive
        gret[n] = git_push_interactive
      end # if gact == "pull"
    end
  end # gitdirs.each_with_index do | gdir,n |
  
  print "\n\n\n"; puts "Results (0: true, -1: false)"
  gitdirs.each_with_index do | gdir,n |
    puts "  #{gdir} (#{gret[n]})"
  end
  print "\n"

  return 0
end # def git_gdir_each( arg=nil )


end # module Git_K247


# How to Use Module
#require "git_k247.rb"
#include Git_K247

#Git_K247.git_commit_interactive



#puts "ToDo: master git branch"
#puts "End of program #{$0}"
__END__

