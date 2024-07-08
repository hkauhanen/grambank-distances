# grambank-distances

Great-circle distance for every language--language pair in Grambank, calculated assuming a perfectly spherical Earth of radius 6,371 km.

- `grambank-distances.csv.gz`: all distances
- `grambank-distances-100closest.csv.gz`: distances to 100 nearest neighbours
- `grambank-distances-500closest.csv.gz`: distances to 500 nearest neighbours
- `grambank-distances-under1000km.csv.gz`: distances to neighbours at most 1000 km away
- `grambank-distances-under5000km.csv.gz`: distances to neighbours at most 5000 km away

To create these files, run the Julia script `jl/distances.jl`. Runtime is on the order of 1 minute on a modest laptop (in 2024).
