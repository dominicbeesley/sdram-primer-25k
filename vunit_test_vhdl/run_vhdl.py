from vunit import VUnit


def encode(tb_cfg):
    return ", ".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("./*.vhd")
lib.add_source_files("../library/mine/*.vhd")
lib.add_source_files("../src/sdramctl.vhd")
lib.add_source_files("../library/3rdparty/winbond/W9825G6KH/W9825G6KH.modelsim.vp", file_type="verilog", defines=dict({ 'T6CL2':'1', 'BL4':'1'}))

tb = lib.test_bench("test_tb")


cfg = tb.add_config("latency_4_cs_delay", generics=dict( \
	FREQ = 64000000
	))


# Run vunit function
vu.main()
