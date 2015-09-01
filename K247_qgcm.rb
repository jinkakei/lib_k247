#!/usr/bin/ruby
# -*- coding: utf-8 -*-

# load libraries
require "numru/gphys"
require "numru/ggraph"
include NumRu
require "~/lib_k247/K247_basic"




class K247_qgcm_data

attr_reader :p, :q
# from monit.nc
attr_reader :ddtkeoc, :ddtpeoc, :emfroc, :et2moc, :etamoc, \
            :kealoc, :pkenoc
# parameters ( from input_parameters.m )
#   I cannot avoid use variable names directoly. @2015-09-01
attr_reader :fnot, :beta, :dxo, :dto, :rhooc, :cpoc, \
            :l_spl, :c1_spl
attr_reader :gpoc, :cphsoc, :rdefoc, :tabsoc, :hoc


def initialize( nc_fn )
# nc_fn: ( return of K247_qgcm_integrate_outdata ) 
  @p = GPhys::IO.open( nc_fn, "p" )
  @q = nil
  init_monit( nc_fn )
# initialize parameters ( from input_parameters.m )
  init_inparam_zdim( nc_fn )
  init_inparam_nodim( nc_fn )
end # initialize

# Create: 2015-09-01
## ToDo : select variables
def init_monit( nc_fn )
  @ddtkeoc = GPhys::IO.open( nc_fn, "ddtkeoc")
  @ddtpeoc = GPhys::IO.open( nc_fn, "ddtpeoc")
  @emfroc = GPhys::IO.open( nc_fn, "emfroc")
  @ermaso = GPhys::IO.open( nc_fn, "ermaso")
  @et2moc = GPhys::IO.open( nc_fn, "et2moc")
  @etamoc = GPhys::IO.open( nc_fn, "etamoc")
  @kealoc = GPhys::IO.open( nc_fn, "kealoc")
  @pkenoc = GPhys::IO.open( nc_fn, "pkenoc")
#  @oc = GPhys::IO.open( nc_fn, "oc")
end # def init_monit( nc_fn )


# Create: 2015-09-01
## ToDo : sophisticate
def init_inparam_zdim( nc_fn )
  @gpoc = GPhys::IO.open( nc_fn, "gpoc" )
  @cphsoc = GPhys::IO.open( nc_fn, "cphsoc" )
  @rdefoc = GPhys::IO.open( nc_fn, "rdefoc" )
  @tabsoc = GPhys::IO.open( nc_fn, "tabsoc" )
  @hoc = GPhys::IO.open( nc_fn, "hoc" )
end # def set_inparam_zdim( nc_fn )


## Create: 2015-09-01
def init_inparam_nodim( nc_fn )
  nc_fu = NetCDF.open( nc_fn )
  anames = nc_fu.att_names
  ## !caution! 
  anames_not_param = ["history", "original"]
    anames_not_param.each do | dname | anames.delete( dname ) end
  anames.each do | aname |
    att_line = nc_fu.att( aname ).get
    val, units, long_name = att_line.split(":")
    tna = NArray[ val.to_f ]
    va_tmp = VArray.new( tna, {"units"=>units, "long_name"=>long_name}, aname)
    instance_variable_set("@#{aname}", va_tmp)
    #puts "  in_para: #{aname}" # 
  end
  nc_fu.close
end # set_inparam_nodim



end # class K247_qgcm_data


=begin
## how to use: K247_qgcm_data
nc_fn = "./outdata_tmp/q-gcm_29_tmp_out.nc"
tmp = K247_qgcm_data.new( nc_fn )

vnames = tmp.instance_variables
vnames.each do | vn |
  p tmp.instance_variable_get( vn )
#  p tmp.instance_variable_get( vn ).get_att("long_name")
end
=end










## tmp method 
def k247_qgcm_modify_grid( apts )
  # apts: axes_parts ( hash, return of gphys_obj.get_axparts_k247 )

# version A.0.0.1 in k247_integrate_qgcmout.rb @2015-08-29
  puts "  ocpo.nc@p: replace X,Y Axis ( 0 at center)"
    nxp = apts['xp']['val'].length
    dx =  apts['xp']['val'][1] - apts['xp']['val'][0]
    apts['xp']['val'] -= dx * ( nxp - 1 ).to_f / 2.0
    nyp = apts['yp']['val'].length
    dy =  apts['yp']['val'][1] - apts['yp']['val'][0]
    apts['yp']['val'] -= dy * ( nyp - 1 ).to_f / 2.0
  puts "  ocpo.nc@p: convert T Axis to [days]"
    apts['time']['val'] *= 365.0
    apts['time']['atts']['units'] = 'days'

end


  # Convert English for KUDPC
  # 2015-07-25 -- Create
  #   read input_parameters.m
  #   make hash inp_val{ "vname" => val}, inp_com = {"vname" => "comment"}
  #  K247_20150725_qgcm_input_parmeters.rb
  # 2015-08-24 -- edit
  #  Comment: layered parameters are difficult to read.
  # 
  # argument: input -- hash
  # return  : inp_val, inp_com -- hash
  def K247_qgcm_read_inpara( input )
    # ex. outdata_CASENAME/input_parameters.m
    inp_fn = input[ "inp_fn" ]
    inp_fu = open( inp_fn, "r")
      # line read ( preparation for layerd parameters )
      lnum = 0; inp_txt = Array.new; inp_txt2 = Array.new
      cini = 0; clen = 1 
      while line = inp_fu.gets
        if ( line[cini,clen] =~ /[a-z]/) # first 1 character is alphabet
          inp_txt[lnum],tmp = line.split(";")
          tmp2, inp_txt2[lnum] = tmp.split("%% ")
          lnum += 1
        end
      end
    inp_fu.close

    inp_val = { "readme"=> "This hash is values of input_parameters.m"}
    inp_com = { "readme"=> "This hash is comments of input_parameters.m"}
      flag_bgn = 1; flag_end = 7
      for n in flag_bgn..flag_end
        vname, val = inp_txt[n].split(" =")
        inp_val.store( vname, val.to_i )
        inp_com.store( vname, inp_txt2[n].chomp )
      end
      para_bgn = 8
        vname_z = [ "zopt", "gpoc", "ah2oc", "ah4oc", "tabsoc", \
              "tocc", "hoc", "gpat", "ah4at", "tabsat", \
              "tat", "hat", "cphsoc", "rdefoc", "cphsat", \
              "rdefat", "aface"]
          flg_z = { "tmp"=>0}
        vname_nlo = [ "ah2oc", "ah4oc", "tabsoc", "tocc", "hoc",  ]
          flg_nlo = { "tmp"=>0}
        vname_nlo0 = [ "gpoc", "cphsoc", "rdefoc"]
          flg_nlo0 = { "tmp"=>0}
        vname_nla = [ "zopt", "ah4at", "tabsat", "tat", "hat" ]
          flg_nla = { "tmp"=>0}
        vname_nla0 = [ "gpat", "cphsat", "rdefat", "aface" ]
          flg_nla0 = { "tmp"=>0}
      for n in para_bgn..lnum-1
        vname, val = inp_txt[n].split("=")
        case vname
        when "%%Derived parameters\n"
          # 
        when "name"
          inp_val.store( vname, val )
          inp_com.store( vname, inp_txt2[n].chomp )
        when "outfloc", "outflat" # p val # ex. " [ 1 1 1 1 1 1 1]"
          tmp, tar = val.split( "[ "); tar2, tmp = tar.split("]")
          tval_arr = tar2.split(" ") # p tval_arr # ex. ["1", "1", "0", "1", "0", "0", "0"]
          val_arr = NArray.int( tval_arr.size )
          for n2 in 0..val_arr.size-1
            val_arr[n2] = tval_arr[n2].to_i
          end
          inp_com.store( vname, inp_txt2[n].chomp )
          inp_val.store( vname, val_arr )
        when *vname_z
          if flg_z[vname] == nil then
            case vname
            when *vname_nlo
              nl = inp_val["nlo"].to_i
            when *vname_nlo0
              nl = inp_val["nlo"].to_i - 1
            when *vname_nla
              nl = inp_val["nla"].to_i
            when *vname_nla0
              nl = inp_val["nla"].to_i - 1
            else
              print "\n\n !WARNING! \n\n"
            end
            nl_arr = NArray.sfloat( nl )
            for n2 in 0..nl-1
              if n2 > 0 then
              # ex. zopt= [zopt   2.00000E+04]
              tmp,val0 = inp_txt[n+n2].split("["+vname)
              val,tmp2 = val0.split("]")
              end
              nl_arr[n2] = val.to_f
            end
            inp_val.store( vname, nl_arr )
            inp_com.store( vname, inp_txt2[n].chomp )
            flg_z.store( vname, 1)
          end
        else
          if ( inp_txt2[n] != nil) 
            inp_val.store( vname, val.to_f )
            inp_com.store( vname, inp_txt2[n].chomp )
          end
        end
      end
    
  # set output paramters (ver. 0.0.1 @2015-08-30)
    inp_okeyno = [ "fnot", "beta", "dxo","dto", "rhooc", \
                   "cpoc", "l_spl", "c1_spl"]
    inp_okeyzi = [ "gpoc", "cphsoc", "rdefoc"]
    inp_okeyz  = [ "tabsoc", "hoc"]
    inp_okey = inp_okeyno[0..-1] + inp_okeyzi[0..-1] + inp_okeyz[0..-1]
    inp_ounit = { "fnot"=>"s-1", "beta"=>"s-1.m-1", "dxo"=>"m", "dto"=>"s", \
                  "rhooc"=>"kg.m-3", "cpoc"=>"J.kg-1.K-1", "l_spl"=>"m", \
                  "c1_spl"=>" ", "gpoc"=>"m.s-2", "cphsoc"=>"cm.s-1", \
                  "rdefoc"=>"m", "tabsoc"=>"K", "hoc"=>"m" }

    inp_okey.each do | ky |
      inp_com[ky].sub!( /layer 1/, "layer n" )
      inp_com[ky].sub!( /mode 1/, "mode n" )
    end

    inp_hash = {"val"=>inp_val, "comment"=>inp_com, \
                "out_units"=>inp_ounit, \
                "out_keyno"=>inp_okeyno, "out_keyz"=>inp_okeyz, \
                "out_keyzi"=>inp_okeyzi, 
                }
    return inp_hash
  end # def K247_qgcm_read_inpara( input )

# 2015-08-30
#   wrapper of K247_qgcm_read_inpara
#   arguments: out_fu:    outfile unit
#              inpara_fn: filename of input paramters
#              ocpo_fn:   filename of ocpo
#              a
def K247_qgcm_write_inpara( input )
out_fu = input["out_fu"]
inpara_fn = input["inpara_fn"]
i_hash = K247_qgcm_read_inpara( { "inp_fn"=>inpara_fn} )
  i_val = i_hash["val"]; i_com = i_hash["comment"]
  i_okeyno = i_hash["out_keyno"]; i_okeyzi = i_hash["out_keyzi"]
  i_okeyz  = i_hash["out_keyz"]
  i_okey   = i_okeyno[0..-1] + i_okeyzi[0..-1] + i_okeyz[0..-1]
  i_ounit = i_hash["out_units"]

ocpo_fn = input["ocpo_fn"] 
grid_z = GPhys::IO.open( ocpo_fn, 'z').grid_copy
grid_zi = GPhys::IO.open( ocpo_fn, 'zi').grid_copy

i_okey.each do | oky |
  if i_okeyz.include?(oky) || i_okeyzi.include?(oky)
    attr_tmp = {"units"=>i_ounit[oky], "long_name"=>i_com[oky]}
    gp_tmp = GPhys.new( grid_zi, VArray.new( i_val[oky], attr_tmp, oky ) ) if i_okeyzi.include?(oky)
    gp_tmp = GPhys.new( grid_z, VArray.new( i_val[oky], attr_tmp, oky ) ) if i_okeyz.include?(oky)
    GPhys::NetCDF_IO.write( out_fu, gp_tmp )
  else
    out_fu.put_att(oky, i_val[oky].to_s  + ":" \
                  + i_ounit[oky] + ":" + i_com[oky] )
  end # if i_okeyz.include?(oky) || i_okeyzi.include?(oky)
end # i_okey.each do | oky |

end # def K247_qgcm_write_inpara( input )



def K247_qgcm_write_monit( input )
out_fu = input["out_fu"]
monit_nf = input[ "monit_fn" ]
# output var names for monit.nc @ 2015-08-30
mon_ovname = [ 'ddtkeoc', 'ddtpeoc', 'emfroc', 'ermaso', \
               'et2moc', 'etamoc', 'kealoc', 'pkenoc']
  mon_vzom = [ 'ddtpeoc', 'emfroc', 'ermaso', 'et2moc', 'etamoc']
  mon_vzo  = [ 'ddtkeoc', 'kealoc']
  mon_vz = mon_vzom + mon_vzo

mon_ovname.each do | vname |
  gp_v = GPhys::IO.open( monit_nf, vname)
#  if mon_vz.include?( vname )
    axes_parts = gp_v.get_axparts_k247
    axes_parts["time"]["name"] = "time_monitor"
        axes_parts["time"]["val"] *= 365.0
        axes_parts["time"]["atts"]["units"] = "days"
    axes_parts["zo"]["name"] = "z" if mon_vzo.include?( vname )
    axes_parts["zom"]["name"] = "zi" if mon_vzom.include?( vname )
      # adjust vertical axis name with ocpo.nc
    new_grid = gp_v.restore_grid_k247( axes_parts )
    gp_v2 = GPhys.new( new_grid, gp_v.data)
    GPhys::NetCDF_IO.write( out_fu, gp_v2 )
end # mon_ovname.each do | vname |

end # def K247_qgcm_write_monit( input )


def K247_qgcm_integrate_outdata( input )
  ocpo_nf = input["ocpo_nf"]; out_nf = input["out_nf"]
  monit_nf = input["monit_nf"]; inpara_nf = input["inpara_nf"]
  out_flag = input["out_flag"]
  
  p ocpo_nf
  p out_nf

  if ( File.exist?(ocpo_nf) ) && ( ! File.exist?(out_nf) ) then
    out_fu = NetCDF.create( out_nf ) if out_flag == true
    vnames = GPhys::IO.var_names( ocpo_nf )
    if (vnames.include?('p') == true) 
      gp_p = GPhys::IO.open( ocpo_nf, 'p')
        apts = gp_p.get_axparts_k247()
        k247_qgcm_modify_grid( apts )
        pgrid_new = gp_p.restore_grid_k247( apts )
        #  p pgrid_new.class
        gp_p2 = GPhys.new( pgrid_new, gp_p.data)
         
        GPhys::NetCDF_IO.write( out_fu, gp_p2 ) if out_flag == true
    else
      puts "\n\n  !!!ERROR!!! #{ocpo_nf} does not have p!\n\n"
      exit -1
    end # if (vnames.include?('p') == true) 

      K247_qgcm_write_monit( { "out_fu"=>out_fu, "monit_fn"=>monit_nf } ) if out_flag == true
      out_fu.put_att("original", ocpo_nf) if out_flag == true
      K247_qgcm_write_inpara( { "out_fu"=>out_fu, "ocpo_fn"=>ocpo_nf, \
                                "inpara_fn"=>inpara_nf} ) if out_flag == true
    out_fu.close if out_flag == true
  else # if ( File.exist?(ocpo_nf) ) then 
    puts "  !!!ERROR!!! #{ocpo_nf} does not exist!" if ( ! File.exist?(ocpo_nf) )
    puts "  !!!ERROR!!! #{out_nf} already exists!" if ( File.exist?(out_nf) )
  end # if ( File.exist?(ocpo_nf) ) then 

end # def K247_qgcm_integrate_outdata

