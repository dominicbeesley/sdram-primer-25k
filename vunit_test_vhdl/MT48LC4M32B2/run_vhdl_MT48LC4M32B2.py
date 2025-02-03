from vunit import VUnit


def encode(tb_cfg):
    return ", ".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()


# Create library 'lib'
fmf = vu.add_library("fmf")
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("../test_tb.vhd")
lib.add_source_files("../../library/mine/*.vhd")
lib.add_source_files("../../src/sdramctl.vhd")
lib.add_source_files("../sdram_wrap/sdram_wrap_MT48LC4M32B2.vhd")
fmf.add_source_files("../../library/3rdparty/fmf/all_packages/*.vhd")
lib.add_source_files("../../library/3rdparty/fmf/all_ram/mt48lc4m32b2.vhd", vhdl_standard="1993")

tb = lib.test_bench("test_tb")
# set for -6 speed grade - hopefully matches the on-die chip in Tang Nano 20K
tb.set_generic('PHASE'             ,'210.0')
tb.set_generic('FREQ'              ,'125000000')
tb.set_generic('T_CAS_EXTRA'       ,'0')
tb.set_generic('LANEBITS'          ,'2')
tb.set_generic('BANKBITS'          ,'2')
tb.set_generic('ROWBITS'           ,'12')
tb.set_generic('COLBITS'           ,'8')
tb.set_generic('trp'               ,'18ns')
tb.set_generic('trcd'              ,'18ns')
tb.set_generic('trc'               ,'60ns')
tb.set_generic('trfsh'             ,'1.8us')
tb.set_generic('trfc'              ,'60ns')


# Run vunit function
vu.main()
