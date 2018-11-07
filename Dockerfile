FROM ubuntu:16.04
ENV usernew="renderaccount"
ENV passwduser="123456"


RUN apt-get update && apt install -y libboost-all-dev git-core tar \
    unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev \
    libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev \
    protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff5-dev libicu-dev libgdal-dev \
    libcairo-dev libcairomm-1.0-dev apache2 apache2-dev \
    libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg

RUN apt-get install -y postgresql postgresql-contrib \
    postgis postgresql-9.5-postgis-2.2 sudo

RUN sudo -u postgres -i
RUN createuser renderaccount
RUN createdb -E UTF8 -O renderaccount gis
RUN  psql --command "\c gis;"
RUN  psql --command "CREATE EXTENSION postgis;"
RUN  psql --command "CREATE EXTENSION hstore;"
RUN  psql --command "ALTER TABLE geometry_columns OWNER TO renderaccount;"
RUN  psql --command "ALTER TABLE spatial_ref_sys OWNER TO renderaccount;"
RUN exit
RUN useradd -m ${usernew} -p ${passwduser}
RUN mkdir ~/src && cd ~/src && git clone git://github.com/openstreetmap/osm2pgsql.git && cd osm2pgsql
RUN sudo apt install make cmake g++ libboost-dev \
    libboost-system-dev libboost-filesystem-dev libexpat1-dev \
    zlib1g-dev libbz2-dev libpq-dev libgeos-dev libgeos++-dev \
    libproj-dev lua5.2 liblua5.2-dev
RUN mkdir build && cd build
RUN cmake ..
RUN make && make install

RUN sudo apt-get install autoconf apache2-dev libtool \
libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev \
gdal-bin libgdal1-dev libmapnik-dev mapnik-utils python-mapnik

RUN cd ~/src && git clone -b switch2osm git://github.com/SomeoneElseOSM/mod_tile.git 
RUN cd mod_tile 
RUN ./autogen.sh

RUN ./configure
RUN make
RUN make install
RUN make install-mod_tile
RUN ldconfig
RUN cd ~/src && git clone git://github.com/gravitystorm/openstreetmap-carto.git
RUN cd openstreetmap-carto
RUN apt install npm nodejs-legacy && npm install -g carto
RUN carto -v 
RUN carto project.mml > mapnik.xml
RUN mkdir ~/data && cd ~/data
RUN wget http://download.geofabrik.de/antarctica-latest.osm.pbf

RUN osm2pgsql -d gis --create --slim  -G --hstore --tag-transform-script \
 ~/src/openstreetmap-carto/openstreetmap-carto.lua -C 2500 \
 --number-processes 1 -S ~/src/openstreetmap-carto/openstreetmap-carto.style ~/data/antarctica-latest.osm.pbf 

CMD sh


