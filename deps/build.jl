using CBindingGen
using Libdl
import Pkg.TOML
import P4est_jll


# setup configuration using ideas from MPI.jl
config_toml = joinpath(first(DEPOT_PATH), "prefs", "P4est.toml")
mkpath(dirname(config_toml))

if !isfile(config_toml)
  touch(config_toml)
end

config = TOML.parsefile(config_toml)

# P4est.toml has 2 keys
#  library  = "" (default) | library name/path
#  include  = "" (default) | include name/path


# Step 1: Check environment variables and update preferences accordingly
if haskey(ENV, "JULIA_P4EST_LIBRARY")
	config["library"] = ENV["JULIA_P4EST_LIBRARY"]
else
	config["library"] = ""
end

if haskey(ENV, "JULIA_P4EST_INCLUDE")
	config["include"] = ENV["JULIA_P4EST_INCLUDE"]
else
	config["include"] = ""
end


open(config_toml, "w") do io
	TOML.print(io, config)
end



# Step 2: Choose the library according to the settings
if isempty(config["library"])
	println("Use p4est library provided by P4est_jll")
	p4est_library = P4est_jll.libp4est_path
else
	println("Use custom p4est library $(config["library"])")
	p4est_library = config["library"]
end



# Step 3: Choose the include path according to the settings
include_directories = String[]
if isempty(config["include"])
	println("Use p4est include path provided by P4est_jll")
	push!(include_directories,
				joinpath(dirname(dirname(P4est_jll.libp4est_path)), "include"))
else
	println("Use custom p4est include path $(config["include"])")
	push!(include_directories, config["include"])
end



# Step 4: Generate binding using the include path according to the settings

# Manually set header files to consider
hdrs = ["p4est.h", "p4est_extended.h", "p8est.h", "p8est_extended.h"]

# Convert symbols in header
include_args = String[]
@show include_directories
for dir in include_directories
	append!(include_args, ("-I", dir))
end
cvts = convert_headers(hdrs, args=include_args) do cursor
	header = CodeLocation(cursor).file
	name   = string(cursor)

	# only wrap the libp4est and libsc headers
	dirname, filename = splitdir(header)
	if !(filename in hdrs ||
		   startswith(filename, "p4est_") ||
		   startswith(filename, "p6est_") ||
		   startswith(filename, "p8est_") ||
			 startswith(filename, "sc_") ||
			 filename == "sc.h" )
		return false
	end
	@show filename

  # Ignore macro hacks
  startswith(name, "sc_extern_c_hack_") && return false

	return true
end

# Write generated C bindings to file
const bindings_filename = joinpath(@__DIR__, "libp4est.jl")
open(bindings_filename, "w+") do io
	generate(io, p4est_library => cvts)
end
