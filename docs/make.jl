
# Copy files and modify them for the docs so that we do not maintain two
# versions manually.
authors_text = read(joinpath(dirname(@__DIR__), "AUTHORS.md"), String)
authors_text = replace(authors_text, "in the [LICENSE.md](LICENSE.md) file" => "under [License](@ref)")
write(joinpath(@__DIR__, "src", "authors.md"), authors_text)

open(joinpath(@__DIR__, "src", "license.md"), "w") do io
  # Point to source license file
  println(io, """
  ```@meta
  EditURL = "https://github.com/trixi-framework/P4est.jl/blob/main/LICENSE.md"
  ```
  """)
  # Write the modified contents
  println(io, "# License")
  println(io, "")
  for line in eachline(joinpath(dirname(@__DIR__), "LICENSE.md"))
    line = replace(line, "[LICENSE.md](LICENSE.md)" => "[License](@ref)")
    println(io, "> ", line)
  end
end

open(joinpath(@__DIR__, "src", "contributing.md"), "w") do io
  # Point to source license file
  println(io, """
  ```@meta
  EditURL = "https://github.com/trixi-framework/P4est.jl/blob/main/CONTRIBUTING.md"
  ```
  """)
  # Write the modified contents
  println(io, "# Contributing")
  println(io, "")
  for line in eachline(joinpath(dirname(@__DIR__), "CONTRIBUTING.md"))
    line = replace(line, "[LICENSE.md](LICENSE.md)" => "[License](@ref)")
    println(io, "> ", line)
  end
end

# If we want to build the docs locally, add the parent folder to the
# load path so that we can use the current development version of P4est.jl.
# See also https://github.com/trixi-framework/Trixi.jl/issues/668
if (get(ENV, "CI", nothing) != "true") && (get(ENV, "JULIA_P4EST_DOC_DEFAULT_ENVIRONMENT", nothing) != "true")
    push!(LOAD_PATH, dirname(@__DIR__))
end

import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Documenter
using P4est

# Define module-wide setups such that the respective modules are available in doctests
DocMeta.setdocmeta!(P4est, :DocTestSetup, :(using P4est); recursive = true)

# Make documentation
makedocs(
  # Specify modules for which docstrings should be shown
  modules = [P4est],
  # Set sitename to P4est
  sitename = "P4est.jl",
  # Provide additional formatting options
  format = Documenter.HTML(
    # Disable pretty URLs during manual testing
    prettyurls = get(ENV, "CI", nothing) == "true",
    # Explicitly add favicon as asset
    # assets = ["assets/favicon.ico"],
    # Set canonical URL to GitHub pages URL
    canonical = "https://trixi-framework.github.io/P4est.jl/stable"
  ),
  # Explicitly specify documentation structure
  pages = [
    "Home" => "index.md",
    "API Reference" => "reference.md",
    "Authors" => "authors.md",
    "Contributing" => "contributing.md",
    "License" => "license.md"
  ],
  # TODO: Clang; make strict = true
  strict = false # to make the GitHub action fail when doctests fail
)

deploydocs(
  repo = "github.com/trixi-framework/P4est.jl",
  devbranch = "main",
  push_preview = true
)
