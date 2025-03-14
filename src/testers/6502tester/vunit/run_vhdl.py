from vunit import VUnit


# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()


# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("./*.vhd")
lib.add_source_files("../shared/*.vhd")
lib.add_source_files("../gowin/primer-25k/src/*.vhd")
lib.add_source_files("../gowin/primer-25k/src/gowin_pll/pll1.vhd")
lib.add_source_files("../../../sdramctl.vhd")
lib.add_source_files("../../../../library/mine/*.vhd")
lib.add_source_files("../../../../library/mine/fishbone/*.vhd")
lib.add_source_files("C:/Gowin/Gowin_V1.9.11_x64/IDE/simlib/gw5a/prim_sim.vhd")
lib.add_source_files("../../../../library/3rdparty/winbond/W9825G6KH/W9825G6KH.modelsim.vp", file_type="verilog", defines=dict({ 'T6CL2':'1', 'BL4':'1'}))


tb = lib.test_bench("test_tb")

tb.set_sim_option('disable_ieee_warnings', True)


#cfg = tb.add_config("SIM", generics=dict(
#   SIM = True
#   ))


# Run vunit function
vu.main()
