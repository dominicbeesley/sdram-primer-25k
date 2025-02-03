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
lib.add_source_files("../library/mine/*.vhd")
lib.add_source_files("../src/sdramctl.vhd")
lib.add_source_files("./sdram_wrap/sdram_wrap_KM432S2030.vhd")
fmf.add_source_files("../library/3rdparty/fmf/all_packages/*.vhd")
lib.add_source_files("../library/3rdparty/fmf/all_ram/km432s2030.vhd", vhdl_standard="1993")

tb = lib.test_bench("test_tb")

tb.set_generic('PHASE'             ,'210.0')
tb.set_generic('FREQ'              ,'125000000')
tb.set_generic('T_CAS_EXTRA'       ,'0')
tb.set_generic('LANEBITS'          ,'2')
tb.set_generic('BANKBITS'          ,'2')
tb.set_generic('ROWBITS'           ,'11')
tb.set_generic('COLBITS'           ,'8')
tb.set_generic('trp'               ,'30ns')
tb.set_generic('trcd'              ,'30ns')
tb.set_generic('trc'               ,'90ns')
tb.set_generic('trfsh'             ,'1.8us')
tb.set_generic('trfc'              ,'90ns')


# Run vunit function
vu.main()
