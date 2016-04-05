FROM kaggle/python1:latest

RUN  # Base ATLAS plus tSNE
    apt-get install -y libatlas-base-dev && \
    # NOTE: we provide the tsne package, but sklearn.manifold.TSNE now does the same
    # job
    cd /usr/local/src && git clone https://github.com/danielfrg/tsne.git && \
    cd tsne && python setup.py install && \
    cd /usr/local/src && git clone https://github.com/ztane/python-Levenshtein && \
    cd python-Levenshtein && python setup.py install && \
    cd /usr/local/src && git clone https://github.com/arogozhnikov/hep_ml.git && \
    cd hep_ml && pip install .  && \
    # chainer
    pip install chainer && \
    # NLTK Project datasets
    mkdir -p /usr/share/nltk_data && \
    # NLTK Downloader no longer continues smoothly after an error, so we explicitly list
    # the corpuses that work
    python -m nltk.downloader -d /usr/share/nltk_data abc alpino \
    averaged_perceptron_tagger basque_grammars biocreative_ppi bllip_wsj_no_aux \
book_grammars brown brown_tei cess_cat cess_esp chat80 city_database cmudict \
comparative_sentences comtrans conll2000 conll2002 conll2007 crubadan dependency_treebank \
europarl_raw floresta framenet_v15 gazetteers genesis gutenberg hmm_treebank_pos_tagger \
ieer inaugural indian jeita kimmo knbc large_grammars lin_thesaurus mac_morpho machado \
masc_tagged maxent_ne_chunker maxent_treebank_pos_tagger moses_sample movie_reviews \
mte_teip5 names nps_chat omw opinion_lexicon panlex_swadesh paradigms \
pil pl196x ppattach problem_reports product_reviews_1 product_reviews_2 propbank \
pros_cons ptb punkt qc reuters rslp rte sample_grammars semcor senseval sentence_polarity \
sentiwordnet shakespeare sinica_treebank smultron snowball_data spanish_grammars \
state_union stopwords subjectivity swadesh switchboard tagsets timit toolbox treebank \
twitter_samples udhr2 udhr unicode_samples universal_tagset universal_treebanks_v20 \
verbnet webtext word2vec_sample wordnet wordnet_ic words ycoe && \
    # Stop-words
    pip install stop-words

    # Prepare for OpenCV 3
RUN apt-get update && \
    # The apt-get version of imagemagick has gone mad, and wants to remove sysvinit.
    apt-get -y build-dep imagemagick && \
    wget http://www.imagemagick.org/download/ImageMagick-6.9.3-7.tar.gz && \
    tar xzf ImageMagick-6.9.3-7.tar.gz && cd ImageMagick-6.9.3-7 && ./configure && \
    make && make install && \
    apt-get -y install libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev && \
    apt-get -y install libtbb2 libtbb-dev libjpeg-dev libtiff-dev libjasper-dev && \
    # apt-get gives you cmake 2.8, which fails to find Py3.4's libraries and headers. The current
    # version is cmake 3.2, which does.
    cd /usr/local/src && git clone https://github.com/Kitware/CMake.git && \
    # --system-curl needed for OpenCV's IPP download, see https://stackoverflow.com/questions/29816529/unsupported-protocol-while-downlod-tar-gz-package/32370027#32370027
    cd CMake && ./bootstrap --system-curl && make && make install && \
    cd /usr/local/src && git clone https://github.com/Itseez/opencv.git

    # Install OpenCV-3 with Python support
RUN cd /usr/local/src/opencv && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_TBB=ON -D WITH_FFMPEG=OFF -D WITH_V4L=ON -D WITH_QT=OFF -D WITH_OPENGL=ON -D PYTHON3_LIBRARY=/opt/conda/lib/libpython3.4m.so -D PYTHON3_INCLUDE_DIR=/opt/conda/include/python3.4m/ -D PYTHON_LIBRARY=/opt/conda/lib/libpython3.4m.so -D PYTHON_INCLUDE_DIR=/opt/conda/include/python3.4m/ .. && \
    make -j $(nproc) && make install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf && ldconfig && \
    cp /usr/local/lib/python3.4/site-packages/cv2.cpython-34m.so /opt/conda/lib/python3.4/site-packages/ 

RUN apt-get -y install libgeos-dev && \
    # pyshp and pyproj are now external dependencies of Basemap
    pip install pyshp pyproj && \
    cd /usr/local/src && git clone https://github.com/matplotlib/basemap.git && \
    export GEOS_DIR=/usr/local && \
    cd basemap && python setup.py install && \
    # Pillow (PIL)
    apt-get -y install zlib1g-dev liblcms2-dev libwebp-dev && \
    pip install Pillow && \
    cd /usr/local/src && git clone https://github.com/vitruvianscience/opendeep.git && \
    cd opendeep && python setup.py develop  && \
    # sasl is apparently an ibis dependency
    apt-get -y install libsasl2-dev && \
    pip install ibis-framework && \
    # Cartopy plus dependencies
    yes | conda install proj4 && \
    pip install packaging && \
    cd /usr/local/src && git clone https://github.com/Toblerity/Shapely.git && \
    cd Shapely && python setup.py install && \
    cd /usr/local/src && git clone https://github.com/SciTools/cartopy.git && \
    cd cartopy && python setup.py install

    # MXNet
RUN cd /usr/local/src && git clone --recursive https://github.com/dmlc/mxnet && \
    cd /usr/local/src/mxnet && cp make/config.mk . && sed -i 's/CC = gcc/CC = gcc-4.8/' config.mk && \
    sed -i 's/CXX = g++/CXX = g++-4.8/' config.mk && \
    sed -i 's/ADD_LDFLAGS =/ADD_LDFLAGS = -lstdc++/' config.mk && \
    make && cd python && python setup.py install
    
    # set backend for matplotlib to Agg
RUN matplotlibrc_path=$(python -c "import site, os, fileinput; packages_dir = site.getsitepackages()[0]; print(os.path.join(packages_dir, 'matplotlib', 'mpl-data', 'matplotlibrc'))") && \
    sed -i 's/^backend      : Qt4Agg/backend      : Agg/' $matplotlibrc_path

    # Stop jupyter nbconvert trying to rewrite its folder hierarchy
RUN mkdir -p /root/.jupyter && touch /root/.jupyter/jupyter_nbconvert_config.py && touch /root/.jupyter/migrated && \
    mkdir -p /.jupyter && touch /.jupyter/jupyter_nbconvert_config.py && touch /.jupyter/migrated && \
    # Stop Matplotlib printing junk to the console on first load
    sed -i "s/^.*Matplotlib is building the font cache using fc-list.*$/# Warning removed by Kaggle/g" /opt/conda/lib/python3.4/site-packages/matplotlib/font_manager.py && \
    # Make matplotlib output in Jupyter notebooks display correctly
    mkdir -p /etc/ipython/ && echo "c = get_config(); c.IPKernelApp.matplotlib = 'inline'" > /etc/ipython/ipython_config.py

    # h2o
    # (This requires python-software-properties; see the MXNet section above for installation.)
    # Java7 install method from http://www.webupd8.org/2012/06/how-to-install-oracle-java-7-in-debian.html
    # and https://stackoverflow.com/a/19391042
RUN apt-get install -y oracle-java7-installer && \
    cd /usr/local/src && mkdir h2o && cd h2o && \
    wget http://h2o-release.s3.amazonaws.com/h2o/latest_stable -O latest && \
    wget --no-check-certificate -i latest -O h2o.zip && rm latest && \
    unzip h2o.zip && rm h2o.zip && cp h2o-*/h2o.jar . && \
    pip install `find . -name "*whl"`

    # Keras setup
    # Keras likes to add a config file in a custom directory when it's
    # first imported. This doesn't work with our read-only filesystem, so we
    # have it done now
RUN python -c "from keras.models import Sequential"  && \
    # Switch to TF backend
    sed -i 's/theano/tensorflow/' /.keras/keras.json  && \
    # Re-run it to flush any more disk writes
    python -c "from keras.models import Sequential; from keras import backend; print(backend._BACKEND)" && \
    # Keras reverts to /tmp from ~ when it detects a read-only file system
    mkdir -p /tmp/.keras && cp /.keras/keras.json /tmp/.keras

