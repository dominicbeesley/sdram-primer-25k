from vunit import VUnit


def encode(tb_cfg):
    return ", ".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("../test_tb.vhd")
lib.add_source_files("../library/mine/*.vhd")
lib.add_source_files("../src/sdramctl.vhd")
lib.add_source_files("./sdram_wrap/sdram_wrap_W9825G6KH.vhd")
lib.add_source_files("../library/3rdparty/winbond/W9825G6KH/W9825G6KH.modelsim.vp", file_type="verilog", defines=dict({ 'T6CL2':'1', 'BL1':'1'}))

tb = lib.test_bench("test_tb")

tb.set_generic('PHASE'             ,'210.0')
tb.set_generic('FREQ'              ,'125000000')
tb.set_generic('T_CAS_EXTRA'       ,'1')
tb.set_generic('LANEBITS'          ,'1')
tb.set_generic('BANKBITS'          ,'2')
tb.set_generic('ROWBITS'           ,'13')
tb.set_generic('COLBITS'           ,'9')
tb.set_generic('trp'               ,'18ns')
tb.set_generic('trcd'              ,'18ns')
tb.set_generic('trc'               ,'60ns')
tb.set_generic('trfsh'             ,'1.8us')
tb.set_generic('trfc'              ,'60ns')


# Run vunit function
vu.main()
