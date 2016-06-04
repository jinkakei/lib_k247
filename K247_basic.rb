
# load libraries
require "numru/gphys"
require "numru/ggraph"
require "narray"
require "numru/dcl"
include NumRu
require "~/lib_k247/K247_basic_nodcl.rb"


# index@2016-06-04
## 既存のクラスにメソッドを追加
#  class NumRu::GPhys
#  class NumRu::VArray
#  class NumRu::VArrayNetCDF
##  NArray operator



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
	
	
## END: 既存のクラスにメソッドを追加



## methods by K247

##  NArray operator
##  Array
##  binary read



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



## Binary read
## for binary read ( bread_* )
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
## end: binary read


__END__


