
# load libraries
require "numru/gphys"
require "numru/ggraph"
require "narray"
require "numru/dcl"
include NumRu
require "~/lib_k247/K247_basic_nodcl.rb"

# 2017-02-08: copy for nonhydro_akitomo
  # ~/lib_k247/K247_basic.rb 
  # -> ~/nonhydro_akitomo/ana/lib_k247_basic.rb


# index@2016-06-04
## 既存のクラスにメソッドを追加
#  class NumRu::GPhys
#  class NumRu::VArray
#  class NumRu::VArrayNetCDF
#  class NumRu::NArrayMiss
##  NArray operator
##  Binary read



## 既存のクラスにメソッドを追加

# GPhysにメソッドを追加
class NumRu::GPhys
	
	# 2015-08-27
	def get_attall_k247
		self.data.get_attall_k247 # added method for VArray
	end
	
	# 2015-08-27
	def get_filename_k247
		self.data.get_filename_k247 # added method for VArrayNetCDF
	end
  
  # 2016-05-11
  #   chg_gphys_k247 do not work on hibiy04_fig7.rb
  # 2015-09-04
  # ToDo: import change grid
  def chg_gphys_k247( chg_hash )
    return GPhys.new( self.grid, self.chg_varray_k247( chg_hash ) )
  end

	# 2015-09-03
	#	
	def chg_varray_k247( chg_hash )
		self.data.chg_varray_k247( chg_hash ) # added method for VArray
	end # def chg_varray_k247( chg_hash )
		
		# 2015-09-03
		def chg_data_k247( chg_hash )
			self.chg_varray_k247( chg_hash )
		end # def chg_data_k247( chg_hash )




	
	# Create: 2015-08-25
	# Change: 2015-08-29: 独立なメソッドから VArray のインスタンスメソッドへ
	#	改名：K247_gphys_get_axis_parts => get_axparts_k247
	#
	# 軸の構成要素を取得（軸の書き換えをするため）
	#	gphys_obj.restore_grid( axes_parts ) と連動
	#
	#【未】
	#	・もっとすっきりできないか？
	#	・ハッシュの階層がキツめ ex. apts["xp"]["atts"]["units"]
	#
	# return   : axes_parts -- hash ( 3 ranks )
	#
	def get_axparts_k247
		axis_names = self.axnames
		axes_parts = { "names" => axis_names}
			# 復元時に必要（hash は要素の順番に関する情報を持たないようなので）
		axis_names.each{ | aname |
			ax = self.coord( aname )
			ax_parts = { "name"=> nil, "atts"=>nil, "val"=>nil}
			  ax_parts["name"] = ax.name
			  ax_parts["atts"] = ax.get_attall_k247
			  ax_parts["val"] = ax.val
			axes_parts[aname] = ax_parts
		}
		return axes_parts
	end # get_axparts_k247
	
	
	# ToDo: 
	#  - sophisticate coding
	# argument: axes_parts - hash ( return of gphys_obj.get_axparts_k247 )
	# return:   grid_new  -- restored grid
	#
	def restore_grid_k247( axes_parts )
    self.class::restore_grid_k247( axes_parts )
  end # def restore_grid_k247( axes_parts )

	def self.restore_grid_k247( axes_parts )
		nax = axes_parts["names"].length
		anames = axes_parts["names"]
		ax = {}
		for n in 0..nax-1
			ax[n] = Axis.new.set_pos( VArray.new( axes_parts[anames[n]]["val"], axes_parts[anames[n]]["atts"], axes_parts[anames[n]]["name"] ) )
		end
		rgrid = Grid.new( ax[0] ) if nax == 1
		rgrid = Grid.new( ax[0], ax[1] ) if nax == 2
		rgrid = Grid.new( ax[0], ax[1], ax[2] ) if nax == 3
		rgrid = Grid.new( ax[0], ax[1], ax[2], ax[3] ) if nax == 4

		return rgrid
  end # def self.restore_grid_k247( axes_parts )
	
	
	
end # class NumRu::GPhys


# VArray にメソッドを追加
class NumRu::VArray

	# 2015-08-24: create
	# 2015-08-26: 独立なメソッドから VArray のインスタンスメソッドへ
	#	改名：K247_gphys_get_attall => get_attall_k247
	#
	# 処理：	attribute をすべて取得
	# return: 	hash ( key: attribute 名、val: attribute の中身)
	#
	# 備考：
	#	GPhysの場合は gp.data.get_attall_k247 のように使う
	#
	def get_attall_k247
		att_names = self.att_names
		if att_names == nil
			puts "\n\n  no attribute \n\n"
			return nil
		end
		att_all = {}
		att_names.each do | aname |
			att_all[ aname ] = self.get_att( aname )
		end
		return att_all
	end


	# 2015-09-03
	#	VArray ÌêðÏXµÄÔ·
	#	ex.1) units ¾¯ðÏXµ½¢
	#		new_data = gp_v.chg_data_k247( { "units" => "cm.s-1"})
	#			{Í convert_units Æ¢¤Ìª éªA
	#			³Ì units ªÔáÁÄ¢½êÉp¢é
	# ToDo
  #   optimize for VArrayNetCDF ( some information are lost now ) @2015-09-03
	# arguments: hash ( "name", "val" ÈOÍ "attribute" ÆµÄµíêé)
	# return:    changed VArray
	def chg_varray_k247( chg_hash )

		unless chg_hash["name"] == nil
			new_name = chg_hash[ "name" ]; chg_hash.delete( "name" )
		else
			new_name = self.name
		end

		unless chg_hash["val"] == nil
			new_val = chg_hash[ "name" ]; chg_hash.delete( "val" )
		else
			new_val = self.val
		end
		
		new_att =  self.get_attall_k247
		chg_hash.keys.each do | k |
			new_att[ k ] = chg_hash[ k ]
		end

		return VArray.new( new_val, new_att, new_name )
	end # def chg_varray_k247( chg_hash )
	

end # class NumRu::VArray
	

# VArrayNetCDF にメソッドを追加
class NumRu::VArrayNetCDF

	# 2015-08-25：create
	# 2015-08-27: 独立なメソッドから VArrayNetCDF のインスタンスメソッドへ
	#	改名：K247_gphys_get_filename => get_filename_k247
	#
	#【未】2015-08-27
	#	VArrayNetCDF の #file メソッドがファイル名を含む情報を返す
	#	が、単なる文字列ではなく、NumRu::NetCDFというクラスで扱い方がわからない。
	#		".to_s" するとファイル名がポインタ情報みたいのになる
	#	
	# return     : orginal file name
	def get_filename_k247
		info = self.inspect # ex. "<'p' in './q-gcm_29_24a_ocpo.nc'  sfloat[961, 961, 2, 3]>"
		  #p info.class # String
		return info.split( " in '" )[1].split( "'" )[0]
	end
	
	
end # class NumRu::VArrayNetCDF


def namiss_get_masked_value_k247( namiss )
	return namiss[ namiss.get_mask.eq(0).where[0] ]
end
  # for GPhys
  #  vmiss = gphys_v.get_att( "missing_value" )[0]
  #
# ??? Cannot add methods to NArrayMiss?
#class NumRu::NArrayMiss
#  #def get_masked_value_k247
#  def get_vmiss_K247
#  #  self.get_mask
#  end
#end #  class NumRu::NArrayMiss
# Error for NArrayNetCDF
#/usr/lib/ruby/vendor_ruby/numru/netcdf_miss.rb:39:in `get_with_miss_and_scaling': undefined method `to_nam' for NumRu::NArrayMiss:Class (NoMethodError)
#	from /usr/lib/ruby/vendor_ruby/numru/gphys/varraynetcdf.rb:261:in `val'
#	from /usr/lib/ruby/vendor_ruby/numru/gphys/gphys.rb:604:in `val'
#	from get_bcuvel.rb:23:in `<main>'	




# 2016-11-11
class Float
  def to_s_k247( dig = 1 )
    if self != 0.0
      lnum = log10( self.abs ).to_i
    else
      lnum = 0
    end
    head = self / ( 10.0**lnum )
    ret = head.round( dig ).to_s + "d" + lnum.to_s
  end
end

## END: 既存のクラスにメソッドを追加



## methods by K247
##  DCL
##  NArray operator
##  Array
##  Binary read


##  DCL
  def gropn_k247( op )
  # !not complete! @ 2017-03-27
    # 2017-05-04: op = 1 or 0
    # 
    DCL.sgscmn( 4 ) # blue-cyan-white-yellow-red
    #DCL.sgscmn( 14 ) # blue-white-red ( lighter than 4 )
    #DCL.sgscmn( 10 ) # default ( short green )
    DCL.gropn( op ) # 1: display, 2: pdf
      DCL.glpset( 'lmiss', true ) # skip missing 
      DCL.sgpset( "lclip", true ) # cut run over
    # display as gpview
      GGraph.set_fig( 'viewport' => [0.15, 0.85, 0.2 , 0.55] )
      DCL.sgpset( 'lcntl', false )
      DCL.uzfact( 0.7 )            # set font size
      DCL.sgpset( 'lfull' , true ) # use full are in the window
      DCL.sgpset( 'lfprop', true ) # use proportional font
      DCL.uscset( 'cyspos', 'B'  ) # move unit y axis
  end # gropn_k247
    # log
      # to fill exceed value
        #DCL::glrset( "RMISS", vmiss ) # to fill exceed value
        # preperation
        #  vmiss = gphys_v.get_att( "missing_value" )[0]
        #  tlev  = tlev0[ 0..-1].to_a
        #  tlev.unshift( vmiss ) 
        #  tlev.push(    vmiss )
      # set_axes
        # set detailed memori-uchi
        #  GGraph.set_axes( "xlabelint" => 0.2, "xtickint" => 0.1 )
        #  GGraph.set_axes( "ylabelint" => 0.2, "ytickint" => 0.1 )
        # delete axes units  
        #  GGraph.set_axes( "yunits" => "" ) # delete axes units
        #  GGraph.set_axes( "xunits" => "" ) # delete axes units
        # no axis  
        #  GGraph.set_axes( "xside" => "tb" ) # deault
        #  GGraph.set_axes( "xside" =>  "b" ) # plot only bottom axis
        #  GGraph.set_axes( "yside" => "lr" ) # deault
        #  GGraph.set_axes( "yside" =>  "l" ) # plot only left  axis
        # 1420 (x.1 degE) -> 142.1 (degE)
        #  DCL.uspset( "mxdgty", 5 ) # max digit number of Y-axis
        #  DCL.uspset( "mxdgtx", 5 ) # max digit number of X-axis
      # write 2nd Axis
      # ( on bottom )
        #  DCL.uzlset( "LOFFSET", true) # for add second axes
        #  DCL::uxsaxs( 'B' )
        #  DCL::uzrset( "XFACT", 86.1 ) # 1 deg E -> km in 39.3 N
        #  DCL::uzrset( "XOFFSET", -142.0 * 86.1 - 11 )
        #  DCL::uxaxdv( "B", 2, 10 ) 
        #  DCL::uxsttl( "B", "x [km]", 0.0 )
      #
      # erase message ( contour interval = .. )
      #  DCL.udpset( 'lmsg', false ) 
      # color bar
      #  GGraph.color_bar( "vcent" => cb_h, "units" => "[cm/s]", \
      #                    "vlength" => cb_l )
      #  # "v*": in V-Coordinate
      #    yoko color-bar
      #       "landscape" => true
      #       "top" => true ( set on top, default: bottom)
      #    tate color-bar ( default)
      #       "portrait" => true
      #       "left" => true ( set on left, default: right)
      #
      #
      #DCL.sgpset( 'lcntl', true )
         # erase contour label -> not work
         # set "label" => false in GGraph.contour option
  #
  #
##  NArray operator

  # 2015-09-12: create
  # ToDo
  #   - treat dimension other than 2D
  def na_max_with_index_k247( na )
    max_val = na.max
    ij= na.eq( max_val ).where 
    ni = na.shape[0]
    max_i = ij[0] % ni; max_j = ij[0] / ni
    #  puts "test: #{na[ max_i, max_j ] } "
    return max_val, max_i, max_j
  end
##  END: NArray operator



##  Binary read
##    for binary read ( bread_* )
# ToDo
#   - cut NArray? ( ex. bread_int < bread_int_noNArray )
#   - kill duplication by "conv_arr1d_to_na"
#   - expand for 4d array
# memo
#   - 2016-02-20: move from read_nhmodel.rb
#       based on nonhydro_akitomo/src/binary_read.rb
  def bread_int( fu, im=1, jm=1 )
    tmp = fu.read( 4 * im * jm ) # integer
    tmp2 = tmp.unpack( "i>*" ) # convert: integer, Big Endian
    if jm > 1
      tmp3 = NArray.int( im, jm )
      for j in 0..jm-1
        tmp3[0..-1,j] = tmp2[(im)*j..(im)*(j+1)-1]
      end
    else   # jm == 1
      if im > 1
        tmp3 = NArray.int( im )
        tmp3[0..-1] = tmp2[0..-1]
      else # im == 1
        tmp3 = tmp2
      end
    end
    return tmp3
  end # def bread_int
  
  def bread_real( fu, im=1, jm=1 )
    tmp = fu.read( 4 * im * jm )
    tmp2 = tmp.unpack( "g*" ) # real, big endian
    tmp3 = NArray.sfloat( im, jm )
    if jm > 1
      tmp3 = NArray.sfloat( im, jm )
      for j in 0..jm-1
        tmp3[0..-1,j] = tmp2[(im)*j..(im)*(j+1)-1]
      end
    else   # jm == 1
      if im > 1
        tmp3 = NArray.sfloat( im )
        tmp3[0..-1] = tmp2[0..-1]
      else # im == 1
        tmp3 = tmp2
      end
    end
    return tmp3
  end # def bread_real
  
  def bread_double( fu, im=1, jm=1 )
    tmp = fu.read( 8 * im * jm )
    tmp2 = tmp.unpack( "G*" ) # double precision, big endian
    if jm > 1
      tmp3 = narray.sfloat( im, jm )
      for j in 0..jm-1
        tmp3[0..-1,j] = tmp2[(im)*j..(im)*(j+1)-1]
      end
    else   # jm == 1
      if im > 1
        tmp3 = NArray.sfloat( im )
        tmp3[0..-1] = tmp2[0..-1]
      else # im == 1
        tmp3 = tmp2
      end
    end
    return tmp3
  end # def bread_double
  
=begin
  def conv_arr1d_to_na( na_type, org_arr, im=1, jm=1) # , km=1, tm=1
    na = sub_set_na( na_type, im, jm )
    
    return na
  end
  
    def sub_set_na( na_type, im, jm )
      case na_type
        when "sfloat"
          if jm > 1
            na = narray.sfloat( im, jm)
          else
            na = narray.sfloat( im )
          end
        when "int"
          if jm > 1
            na = narray.int( im, jm)
          else
            na = narray.int( im )
          end
        else
          puts "not match na_type: #{na_type}"
          return false
      end
      return na
    end # def sub_set_na
=end
##  end: Binary read



__END__


