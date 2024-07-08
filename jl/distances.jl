# Computes great-circle distances between every pair of languages in Grambank.
#
# Assumes a spherical Earth of radius 6,371 km.
#
#
# - Henri Kauhanen 2024



using CodecZlib
using CSV
using DataFrames
using ZipFile


# computes great-circle distance between (phi1, lambda1) and (phi2, lambda2)
function greatcircle(phi1::Float64, lambda1::Float64, phi2::Float64, lambda2::Float64)
  return 2 .* 6_371 .* asin.(sqrt.(0.5 .* (1 .- cos.(phi2 .- phi1) .+ cos.(phi1) .* cos.(phi2) .* (1 .- cos.(lambda2 .- lambda1)))))
end


# computes distances between all pairs of languages in dataframe 'languages'
function compute_distances(languages::DataFrame)
  # select only columns we need
  languages = select(languages, :ID, :Latitude, :Longitude)

  # some languages are missing latitudes and longitudes
  languages = dropmissing(languages)

  # cross join
  languages = crossjoin(languages, languages, makeunique=true)

  # remove self-pairs
  subset!(languages, [:ID, :ID_1] => (a,b) -> a .!= b)

  # group by language ID
  languages = groupby(languages, :ID)

  for df in languages
    # compute distance
    transform!(df, [:Latitude, :Longitude, :Latitude_1, :Longitude_1] => ((a,b,c,d) -> greatcircle.(deg2rad.(a), deg2rad.(b), deg2rad.(c), deg2rad.(d))) => :distance)

    # sort by increasing distance
    sort!(df, :distance)
  end

  # collect results, adding rank column
  languages = transform(languages, eachindex => :rank)

  languages = select(languages, :ID, :ID_1, :distance, :rank)

  rename!(languages, [:language_ID, :neighbour_ID, :distance, :rank])

  return languages
end


# temporary file to hold language data
langfile = tempname()


# obtain Grambank language data
tmpfile = tempname()
gb = download(
              "https://zenodo.org/records/7844558/files/grambank/grambank-v1.0.3.zip?download=1",
              tmpfile
             )

# open zipfile
r = ZipFile.Reader(tmpfile)

# get index of language data file inside zipfile
i = findfirst(occursin.("languages.csv", [f.name for f in r.files]))

# write out
write(langfile, read(r.files[i], String))


# read back in
langs = CSV.read(langfile, DataFrame)


# compute distances
distances = compute_distances(langs)


# write results
CSV.write("../grambank-distances.csv.gz", distances, compress=true)
CSV.write("../grambank-distances-under5000km.csv.gz", subset(distances, :distance => d -> d .<= 5000), compress=true)
CSV.write("../grambank-distances-under1000km.csv.gz", subset(distances, :distance => d -> d .<= 1000), compress=true)
CSV.write("../grambank-distances-500closest.csv.gz", subset(distances, :rank => r -> r .<= 500), compress=true)
CSV.write("../grambank-distances-100closest.csv.gz", subset(distances, :rank => r -> r .<= 100), compress=true)



