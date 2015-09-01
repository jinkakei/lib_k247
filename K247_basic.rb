
# load libraries
require "numru/gphys"
require "numru/ggraph"
require "narray"
require "numru/dcl"
include NumRu



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
	
	
	# Create: 2015-08-25
	# Change: 2015-08-29: 独立なメソッドから VArray のインスタンスメソッドへ
	#	改名：K247_gphys_restore_grid => restore_grid_k247
	#
	# 軸の構成要素から Grid を作成
	#	gphys_obj.get_axparts_k247 と対になる
	#
	# ToDo: 
	#	・記述が泥臭い
	#	・オブジェクトから呼ぶのがちょっと違和感あるが、、、
	#
	# argument: axes_parts - hash ( return of gphys_obj.get_axparts_k247 )
	# return:   grid_new  -- restored grid
	#
	def restore_grid_k247( axes_parts )
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
	end # def K247_gphys_restore_grid( axes_parts )
	
	
	
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
	
