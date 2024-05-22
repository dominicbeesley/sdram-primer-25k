from vunit import VUnit


# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()


# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("./*.vhd")
lib.add_source_files("../test6502/src/*.vhd")
lib.add_source_files("../test6502/src/gowin_pll/pll1.vhd")
lib.add_source_files("../../../../library/mine/*.vhd")
lib.add_source_files("../../../../library/mine/fishbone/*.vhd")
lib.add_source_files("C:/Gowin/Gowin_V1.9.9.02_x64/IDE/simlib/gw5a/prim_sim.vhd")

tb = lib.test_bench("test_tb")

tb.set_sim_option('disable_ieee_warnings', True)


#cfg = tb.add_config("SIM", generics=dict(
#   SIM = True
#   ))


# Run vunit function
vu.main()
