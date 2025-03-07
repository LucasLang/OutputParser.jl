module OutputParser

export parse_output, parse_float, parse_int, parse_ORCA_structure, parse_ZFStensor_Heff, parse_gtensor_EPRNMR, parse_Aiso_EPRNMR

"""
nuclei is a list of nuclei in the format "18H", where the number is the index in the
xyz structure (starting counting at 0).
"""
function parse_Aiso_EPRNMR(file::IOStream, nuclei)
    Aiso_values = Vector{Float64}(undef, 0)
    for nucleus in nuclei
        seekstart(file)   # move pointer back to beginning
        searchstringfound, currentline = read_until_hit(file, ["ORCA EPR/NMR", "ELECTRIC AND MAGNETIC", " $nucleus ", "A(iso)"])
        if searchstringfound
            words = split(currentline)
            Aiso = parse(Float64, words[6])
            push!(Aiso_values, Aiso)
        else
            error("The combination of search strings was not found in the output file!")
        end
    end
    return Aiso_values
end

function parse_Aiso_EPRNMR(filename, nuclei)
    file = open(filename, "r")
    Aiso_values = parse_Aiso_EPRNMR(file, nuclei)
    close(file)
    return Aiso_values
end

function parse_gtensor_EPRNMR(file::IOStream)
    g = Matrix{Float64}(undef, 3, 3)
    searchstringfound, currentline = read_until_hit(file, ["ORCA EPR/NMR", "The g-matrix"])
    for row in 1:3
        currentline = readline(file)
	words = split(currentline)
	for col in 1:3
            g[row, col] = parse(Float64, words[col])
        end
    end
    return g
end

function parse_gtensor_EPRNMR(filename)
    file = open(filename, "r")
    g = parse_gtensor_EPRNMR(file)
    close(file)
    return g
end

"""
method can be either CASSCF or NEVPT2.
"""
function parse_ZFStensor_Heff(file::IOStream, method)
    D = Matrix{Float64}(undef, 3, 3)
    searchstringfound, currentline = read_until_hit(file, ["QDPT WITH $method DIAGONAL ENERGIES", "ZERO-FIELD", "EFFECTIVE", "Raw matrix"])
    for row in 1:3
        currentline = readline(file)
	words = split(currentline)
	for col in 1:3
            D[row, col] = parse(Float64, words[col])
        end
    end
    return D
end

function parse_ZFStensor_Heff(filename, method)
    file = open(filename, "r")
    D = parse_ZFStensor_Heff(file, method)
    close(file)
    return D
end

function parse_ORCA_structure(file::IOStream)
    searchstringfound, currentline = read_until_hit(file, ["CARTESIAN COORDINATES"])
    atoms = Vector{String}(undef, 0)
    coordinates = Vector{Vector{Float64}}(undef, 0)
    if searchstringfound
        readline(file)
        endreached = false
        while !endreached
            currentline = readline(file)
            if currentline == ""
                endreached = true
            else
                words = [String(word) for word in split(currentline)]
                push!(atoms, words[1])
                x = parse(Float64, words[2])
                y = parse(Float64, words[3])
                z = parse(Float64, words[4])
                push!(coordinates, [x,y,z])
            end
        end
    else
        error("The molecular structure could not be read. Please check the ORCA output file!")
    end
    return atoms, coordinates
end

function parse_ORCA_structure(filename)
    file = open(filename, "r")
    atoms, coordinates = parse_ORCA_structure(file)
    close(file)
    return atoms, coordinates
end

"""
Extract a number from a log file.
You can provide any number of searchstrings.
linenumber is the line containing the number relative to the one where the last search string was found. 0 means that the number is in the same line as the last search string.
wordnumber is the index of the word that represents the number to be parsed. An index of 0 corresponds to the first word in the line.
"""
function parse_output(file::IOStream, searchstrings, linenumber, wordnumber)
    searchstringfound, currentline = read_until_hit(file, searchstrings)
    if searchstringfound
        for line in 1:linenumber
            currentline = readline(file)
        end
        words = split(currentline)
        return words[wordnumber+1]
    end
    error("The combination of search strings was not found in the output file!")
end

"""
This version is used if only one parse is supposed to be done and then the file closed again.
"""
function parse_output(filename, searchstrings, linenumber, wordnumber)
    file = open(filename, "r")
    word = parse_output(file, searchstrings, linenumber, wordnumber)
    close(file)
    return word
end

function read_until_hit(file, searchstrings)
    currentline = ""
    searchstringfound=false
    for searchstring in searchstrings
        searchstringfound=false
        while (!eof(file) && !searchstringfound)
            currentline = readline(file)
            searchstringfound = occursin(searchstring, currentline)
        end
    end
    return searchstringfound, currentline
end

function parse_type(file, searchstrings, linenumber, wordnumber, typ)
    str = parse_output(file, searchstrings, linenumber, wordnumber)
    value = try
        parse(typ, str)
    catch e
        if isa(e, ArgumentError)
            error("The word $str encountered at the specified location in the output file cannot be interpreted as type $(typ)!")
        else
            throw(e)
        end
    end
    return value
end

parse_float(file, searchstrings, linenumber, wordnumber) = parse_type(file, searchstrings, linenumber, wordnumber, Float64)
parse_int(file, searchstrings, linenumber, wordnumber) = parse_type(file, searchstrings, linenumber, wordnumber, Int64)

end
