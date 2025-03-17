#!/bin/bash

cd $(dirname $0)

mkdir -p platforms

find ../../meta-hilscher-netfield-*/documentation/platforms -type f -exec cp {} platforms/ \;

echo '==================
Platform Specifics
==================

.. toctree::
   :maxdepth: 1
' > platforms/index.rst

for f in $(ls platforms/*.rst); do
    [ "$f" == "platforms/index.rst" ] && continue
    f=$(basename $f)
    echo "   ${f%.*}" >> platforms/index.rst
done

echo '
.. only::  subproject and html

   Indices
   =======

   * :ref:`genindex`
' >> platforms/index.rst
