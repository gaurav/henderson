The Junius Henderson Field Note Project
=======================================

Who was Junius Henderson?
-------------------------

Junius Henderson was the first curator of the University of Colorado
Museum of Natural History. Between 1905 and 1931, he kept 13 notebooks
(1,672 pages in total) detailing his travels across the Southern Rocky 
Mountains of North America and elsewhere. These notebooks were scanned
by the National Snow and Ice Data Center (NSIDC).

You can read more about him [on Wikipedia](http://en.wikipedia.org/wiki/Junius_Henderson);
we have uploaded all his notebooks (and some of his photographs)
[to the Wikimedia Commons](http://commons.wikimedia.org/wiki/Category:Junius_Henderson).

Workflow
--------

1. Install the `WWW::Wikisource` module (from the `WWW-Wikisource` directory).

2. Run `wikisource2xml.pl 'Index:Name of Index on Wikisource.djvu' > download.xml` to download an XML version of the Wikisource document identified by the provided Index. `wikisource2xml.pl` should have been installed to your path 

3. In the [`scripts`](scripts/) directory:

    1. Run `perl concat.pl download.xml > download_concat.txt`; this will create a "concat" file which combines multiple pages so that entries are divided by `{{new-entry}}` tags.

    2. Run `perl results.pl download.xml` to calculate the per-page statistics for annotations on this page. Remember to use the `--skip` command line option to skip front matter.

    3. Similarly, `perl results_concat.pl < download_concat.txt` will generate per-*entry* statistics for annotations. Remember to use the `--skip` command line option to skip entries which cover front matter.

    4. Finally, run `perl concat2stuff.pl dwc < download_concat.txt > download_dwc.csv` to write out a CSV file using DarwinCore headers.

    5. You can use `list.pl` and `list_concat.pl` to generate a list of all annotations detected in XML and "concat" files respectively.

External links
--------------

For more details, please read the following blog posts:

* [An Ode to Founders and a Field Notes Challenge: Part 1](http://soyouthinkyoucandigitize.wordpress.com/2011/11/28/an-ode-to-founders-and-a-field-notes-challenge-part-1/)

* Field Note Challenge Part 2: [Veni, Vidi, Wiki](http://soyouthinkyoucandigitize.wordpress.com/2011/12/05/field-note-challenge-part-2-veni-vidi-wiki/)

* Field Notes Challenge Part 3: [New Year's Digital Resolutions](http://soyouthinkyoucandigitize.wordpress.com/2012/01/06/field-notes-challenge-part-3-new-years-digital-resolutions/)

* Field Notes Challenge Part 4: [Help, 'Cause We Need Somebod(y/ies)](http://soyouthinkyoucandigitize.wordpress.com/2012/01/12/field-notes-challenge-part-4-help-cause-we-need-somebodies/)

* Field Notes Challenge Part 4.5: [JHFNP, Post 4.5](http://soyouthinkyoucandigitize.wordpress.com/2012/01/23/jhfnp-post-4-5/)
