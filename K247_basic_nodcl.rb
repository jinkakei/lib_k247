# 2016-06-04: create for tmsserv ( no numru, dcl, gphys)

#index@2016-06-04
##  General methods
##  Array
##  Add method
##  Physical Oceanography



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


  def system_k247( cmd_str )
    puts(   cmd_str )
    system( cmd_str )
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




## Add method
class Float
  # 2016-11-11
  def to_s_k247( dig = 1 )
    lnum = log10( self ).to_i
    head = self / ( 10.0**lnum )
    ret = head.round( dig ).to_s + "d" + lnum.to_s
  end
end

## END:  Add method




## Physical Oceanography

  # 2014-12-27: create
  # 2016-06-13: copy
	# input：in-situ temperature [deg C]、practical salinity []、in-situ pressure [dbar] 
	#	-> #calc_potential_temperature( input )
	#		@tarr, @sarr, @parr
	#	calc_ptemp_for_NArray ( wrapper of calc_potential_temperature )
	#	variable: reference pressure( pref ), default is 0 [dbar]
	# output：potential temperature
	# formulation：UNESCO 1983 -- http://ocean.jfe-advantech.co.jp/sensor/img/density.pdf
	class K247_calc_ptemp_SetVar
		
	  # initialize
		def initialize
		  # input for array
			@tarr = nil
			@sarr = nil
			@parr = nil
		  # variable
			@pref = 0 # dbar
		  # 
			@t_fac = 1.00024
		  # for gamma
			@a0 =  3.5803 * 10.0**-5.0
			@a1 =  8.5258 * 10.0**-6.0
			@a2 = -6.8360 * 10.0**-8.0
			@a3 =  6.6228 * 10.0**-10.0
			@b0 =  1.8932 * 10.0**-6.0
			@b1 = -4.2393 * 10.0**-8.0
			@c0 =  1.8741 * 10.0**-8.0
			@c1 = -6.7795 * 10.0**-10.0
			@c2 =  8.7330 * 10.0**-12.0
			@c3 = -5.4481 * 10.0**-14.0
			@d0 = -1.1351 * 10.0**-10.0
			@d1 =  2.7759 * 10.0**-12.0
			@e0 = -4.6206 * 10.0**-13.0
			@e1 =  1.8676 * 10.0**-14.0
			@e2 = -2.1687 * 10.0**-16.0
		end # def initialize
		
		attr_accessor :pref
		attr_accessor :tarr
		attr_accessor :sarr
		attr_accessor :parr
	end # class K247_calc_ptemp_SetVar
	
  # 2016-06-13: modify
  # 2014-12-27: create
	# ToDo: simplify
	#	theta = K247_calc_ptemp.new
	#	  theta.tarr = ctemp; theta.sarr = cpsal; theta.parr = cpres
	#	  theta_arr = theta.calc_ptemp_for_NArray()
	#		theta_arr[cmerged_inval_index] = rmiss00
	#		theta_arr = NArrayMiss.to_nam( theta_arr, ctemp.get_mask)
	class K247_calc_ptemp < K247_calc_ptemp_SetVar
		
	  # initialize
		def initialize(  )
			super # 
		end # def initialize()
		
		
	  # 2014-12-27
		# ToDo: check shapes of @tarr, @sarr, @parr
		# ToDo: sophisticate
		# 2014-12-28
		#	[suspend] use NArrayMiss?
		#		NArrayMiss.to_nam(array ,mask) ?
		#			ex. theta = NArrayMiss.to_nam( theta0 , temp_arr.get_mask)
		def calc_ptemp_for_NArray()
			n_dim = @tarr.dim
			n_shape = @tarr.shape
			
			if (n_dim == 1) then
				theta_arr = NArray.sfloat( n_shape[0] )
				for n0 in 0..n_shape[0]-1
					theta_arr[n0] = calc_potential_temperature( {'s'=>@sarr[n0], 't'=>@tarr[n0], 'p'=>@parr[n0]} )
				#	p @sarr[n0], @tarr[n0], @parr[n0]
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 1) then
			if (n_dim == 2) then
				theta_arr = NArray.sfloat( n_shape[0], n_shape[1])
				for n0 in 0..n_shape[0]-1
				for n1 in 0..n_shape[1]-1
					theta_arr[n0, n1] = calc_potential_temperature( {'s'=>@sarr[n0, n1], 't'=>@tarr[n0, n1], 'p'=>@parr[n0, n1]} )
				#	p @sarr[n0], @tarr[n0], @parr[n0]
				end # for n1 in 0..n_shape[1]-1
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 2) then
			if (n_dim == 3) then
				theta_arr = NArray.sfloat( n_shape[0], n_shape[1], n_shape[2])
				for n0 in 0..n_shape[0]-1
				for n1 in 0..n_shape[1]-1
				for n2 in 0..n_shape[2]-1
					theta_arr[n0, n1, n2] = calc_potential_temperature( {'s'=>@sarr[n0, n1, n2], 't'=>@tarr[n0, n1, n2], 'p'=>@parr[n0, n1, n2]} )
				end # for n2 in 0..n_shape[2]-1
				end # for n1 in 0..n_shape[1]-1
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 3) then
			if (n_dim == 4) then
				theta_arr = NArray.sfloat( n_shape[0], n_shape[1], n_shape[2], n_shape[3])
				for n0 in 0..n_shape[0]-1
				for n1 in 0..n_shape[1]-1
				for n2 in 0..n_shape[2]-1
				for n3 in 0..n_shape[3]-1
					theta_arr[n0, n1, n2, n3] = calc_potential_temperature( {'s'=>@sarr[n0, n1, n2, n3], 't'=>@tarr[n0, n1, n2, n3], 'p'=>@parr[n0, n1, n2, n3]} )
				end # for n3 in 0..n_shape[3]-1
				end # for n2 in 0..n_shape[2]-1
				end # for n1 in 0..n_shape[1]-1
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 4) then
			
			return theta_arr
		end # def calc_ptemp_for_NArray()
		
		
		def calc_potential_temperature( input )
			s0 = input['s'] # practical salinity []
			p0 = input['p'] # in-situ pressure [dbar]
			t0 = input['t'] # in-situ temperature [deg C]
			
			t = @t_fac * t0
			h = @pref - p0
			xk = h * calc_gamma(s0, t, p0)
			t = t + 0.5 * xk
			q = xk
			p = p0 + 0.5 * h
			xk = h * calc_gamma(s0, t, p)
			t = t + 0.29289322 * ( xk - q )
			q = 0.58578644 * xk + 0.121320344 * q
			xk = h * calc_gamma(s0, t, p)
			t = t + 1.707106781 * ( xk - q )
			q = 3.414213562 * xk - 4.121320344 * q
			p = p + 0.5 * h
			xk = h * calc_gamma(s0, t, p)
			theta = 0.99976 * ( t + (xk - 2.0 * q) / 6.0)
			return theta
		end # def calc_potential_temperature( input )
		
		def calc_gamma( s, t, p)
			return \
				( @a0 + @a1 * t + @a2 * t**2.0 + @a3 * t**3.0 \
					+ (@b0 + @b1 * t) * (s - 35.0) \
					+ (@c0 + @c1 * t + @c2 * t**2.0 + @c3 * t**3.0 + (@d0 + @d1 * t) * (s - 35.0) ) * p \
					+ (@e0 + @e1 * t + @e2 * t**2.0) * p**2.0 )
		end # def calc_gamma( s, t, p)
		
	end # class K247_calc_ptemp < K247_calc_ptemp_SetVar
	
	



  # 2014-12-27
	# input：potential temperature [deg C]、practical salinity []
	#	-> @tharr, @sarr
	# output: potential density
	#
	# Main: calc_rhoo_for_NArray ( wrapper of calc_rhoo  )
	#
	# formulatin：Data Assimilation sytem at Kyoto-University
	#
	class K247_calc_rhoo_SetVar
		
	  # initialize
		def initialize
		  # input for array
			@tharr = nil
			@sarr = nil
			
		  # constants
			@a0 = 999.842594
			@a1 =  6.793952 * 10.0**-2.0
			@a2 = -9.095290 * 10.0**-3.0
			@a3 =  1.001685 * 10.0**-4.0
			@a4 = -1.120083 * 10.0**-6.0
			@a5 =  6.536332 * 10.0**-9.0
			@b0 =  0.824493*10.0**0.0
			@b1 = -4.0899 * 10.0**-3.0
			@b2 =  7.6438 * 10.0**-5.0
			@b3 = -8.2467 * 10.0**-7.0
			@b4 =  5.3875 * 10.0**-9.0
			@b5 = -5.72466 * 10.0**-3.0
			@b6 =  1.0227 * 10.0**-4.0
			@b7 = -1.6546 * 10.0**-6.0
			@b8 =  4.8314 * 10.0**-4.0
		end # def initialize
		
		attr_accessor :tharr
		attr_accessor :sarr
	end # class K247_calc_rhoo_SetVar
	
	
	
  # 2016-06-14: modify
  # 2014-12-27: create
  # ToDo:
  #   - error for missing value -999.99
	#	rhoo = K247_calc_rhoo.new
	#	  rhoo.tharr = theta_arr; rhoo.sarr = cpsal
	#	  rhoo_arr = rhoo.calc_rhoo_for_NArray
	#		rhoo_arr[cmerged_inval_index] = rmiss00
	#		rhoo_arr = NArrayMiss.to_nam( rhoo_arr, ctemp.get_mask)
	class K247_calc_rhoo < K247_calc_rhoo_SetVar
		
	  # initialize
		def initialize(  )
			super # 
		end # def initialize()
		
		
	  # 2014-12-27
		# ToDo:
		#	- check array size ( @tharr, @sarr )
		#	- sophisticate
		def calc_rhoo_for_NArray()
			n_dim = @tharr.dim
			n_shape = @tharr.shape
			
			if (n_dim == 1) then
				rhoo_arr = NArray.sfloat( n_shape[0] )
				for n0 in 0..n_shape[0]-1
					rhoo_arr[n0] = calc_rhoo( {'s'=>@sarr[n0], 'theta0'=>@tharr[n0]} )
				#	p @sarr[n0], @tharr[n0], @parr[n0]
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 1) then
			if (n_dim == 2) then
				rhoo_arr = NArray.sfloat( n_shape[0], n_shape[1])
				for n0 in 0..n_shape[0]-1
				for n1 in 0..n_shape[1]-1
					rhoo_arr[n0, n1] = calc_rhoo( {'s'=>@sarr[n0, n1], 'theta0'=>@tharr[n0, n1]} )
				#	p @sarr[n0], @tharr[n0], @parr[n0]
				end # for n1 in 0..n_shape[1]-1
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 2) then
			if (n_dim == 3) then
				rhoo_arr = NArray.sfloat( n_shape[0], n_shape[1], n_shape[2])
				for n0 in 0..n_shape[0]-1
				for n1 in 0..n_shape[1]-1
				for n2 in 0..n_shape[2]-1
					rhoo_arr[n0, n1, n2] = calc_rhoo( {'s'=>@sarr[n0, n1, n2], 'theta0'=>@tharr[n0, n1, n2]} )
				end # for n2 in 0..n_shape[2]-1
				end # for n1 in 0..n_shape[1]-1
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 3) then
			if (n_dim == 4) then
				rhoo_arr = NArray.sfloat( n_shape[0], n_shape[1], n_shape[2], n_shape[3])
				for n0 in 0..n_shape[0]-1
				for n1 in 0..n_shape[1]-1
				for n2 in 0..n_shape[2]-1
				for n3 in 0..n_shape[3]-1
					rhoo_arr[n0, n1, n2, n3] = calc_rhoo( {'s'=>@sarr[n0, n1, n2, n3], 'theta0'=>@tharr[n0, n1, n2, n3]} )
				end # for n3 in 0..n_shape[3]-1
				end # for n2 in 0..n_shape[2]-1
				end # for n1 in 0..n_shape[1]-1
				end # for n0 in 0..n_shape[0]-1
			end # if (n_dim == 4) then
			
			return rhoo_arr
		end # def calc_ptemp_for_NArray()
		
		
	  # 2014-12-27: 
		def calc_rhoo( input )
			s = input['s'] # practical salinity []
			th = input['theta0'] # potential temperature [deg C] at 0 dabar
			
		  # K247_DASys_Calc_rhoo
			sroot = s**0.5
			rhoo = ( @a0 \
				+ th *( @a1 + th * ( @a2 + th * ( @a3 + th *( @a4 + @a5 * th )))) \
				+ s *( ( @b0 + th *( @b1+ th * ( @b2 + th * ( @b3 + @b4 * th )))) \
					+ sroot * ( @b5 + th * ( @b6 + @b7 * th ) ) + @b8 * s ) \
				- 1000.0 )  # σ
				
			#rhoo = ( 999.842594 \
			#	+ t*(6.793952*10.0**2 + t*(-9.095290*10.0**3	  \
			#		+ t*(1.001685*10.0**4 + t*(-1.120083*10.0**6	\
			#		+ 6.536332*10.0**9*t))))					\
			#	+ s*( (0.824493*10.0**0 + t*(-4.0899*10.0**3	  \
			#		+ t*(7.6438*10.0**5 + t*(-8.2467*10.0**7		\
			#		+ 5.3875*10.0**9*t)))) + sroot*(-5.72466*10.0**3 \
			#		+ t*(1.0227*10.0**4 - 1.6546*10.0**6*t))		\
			#		+ 4.8314*10.0**4*s) \
			#	- 1000.0 )  # σ
				  
			return rhoo
		end # def calc_potential_temperature( input )
		
	end # class K247_calc_ptemp < K247_calc_ptemp_SetVar
## End: Physical Oceanography
