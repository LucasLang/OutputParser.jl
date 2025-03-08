`OutputParser.jl` is a small Julia package that contains functions for extracting information from text files.
The basic functionality (functions like `parse_float`) can be used for parsing any type of text file,
but some more specialized functions are specific to extracting information from quantum-chemical output files created by the ORCA program.

The basic idea is that you search for a hierarchy of search strings.
More concretely, you search for the first occurrence of the first search string, then for the first occurrence of the second search string **after this point**, etc.
Once the last search string in the hierarchy is found, one navigates to the required piece of data via specifying a line and (space-separated) word offset.
This approach using a hierarchy of search strings is helpful when the same type of data (for example UV/Vis transition energies) are available at different levels of theory (for example CASSCF and NEVPT2).
