BibApp "Solr Home" Directory
=============================

This directory contains the default BibApp settings / configurations
for Solr.  BibApp requires Solr to run, but it does not require that
you use this default "Solr Home" directory (For more info, see 
"Running BibApp on a Separate Solr Install" below).


Basic Directory Structure
-------------------------

The Solr Home directory typically contains the following subdirectories...

   conf/
        This directory is mandatory and contains the mandatory 
        BibApp-specific solrconfig.xml and schema.xml for Solr.  It also
        includes other optional configurations for Solr.

   data/
        This directory is the default location where Solr will keep your
        BibApp index, and is used by the replication scripts for dealing 
        with snapshots.  You can override this location in the solrconfig.xml
        and scripts.conf files. Solr will create this directory if it
        does not already exist.

   lib/
        This directory is optional (and not included with BibApp).  If it exists, 
        Solr will load any Jars found in this directory and use them to resolve 
        any "plugins" specified in your solrconfig.xml or schema.xml 
        (ie: Analyzers, Request Handlers, etc...)

   bin/
        This directory is optional (but included with BibApp).  It is the default location used for
        keeping the Solr replication scripts.

        
Running BibApp on a Separate Solr Install
-----------------------------------------

[WARNING: Although this logically should work, it hasn't been tested yet!]

As mentioned above, this folder contains the default Solr configurations for
BibApp.  However, you may choose to run BibApp using a pre-existing Solr
installation/setup at your institution.  To run BibApp with a separate
Solr installation, you'll need to do the following:

[1] Copy this "BibApp Solr Home" directory to the machine running Solr at
your institution.  Although you probably could get away with just copying
over the default 'schema.xml' and 'solrconfig.xml' configurations for BibApp. 

[2] Startup an instance of Solr which is pointing to the location where you 
moved your "BibApp Solr Home" directory to.  Reference the Solr documentation 
if you are unsure how to do this.

[3] Before starting up BibApp, you will need to customize how BibApp initializes
with Solr, so that BibApp can communicate with your external Solr installation.
In particular, you'll want to add one or more of the following variables 
in your /config/environment.rb (or /environments/production.rb, etc.):

[3a] If Solr is still on the same machine as BibApp, you should just be able
to change the following variables and still be able to use the "rake solr:start"
and "rake solr:stop" commands from your [bibapp] directory:

SOLR_PATH -> full path of solr installation directory  (e.g. "/usr/local/solr")
             on the local machine

SOLR_HOME_PATH -> full path of 'bibapp-solr' (e.g. "/usr/local/bibapp-solr")
                  on the local machine

SOLR_JAVA_OPTS -> Allows you to override the default java options of Solr to 
                  provide it with more memory, etc.
                  (e.g. "-Xms256M -Xmx512M")

[3b] If Solr is on a separate machine, you can still point BibApp at it by
modifying the following variable:

SOLR_URL -> Allows you to point to a Solr instance on an entirely separate machine
            (e.g. "http://my-other-machine:8983/solr")

  [WARNING] Running Solr on another machine means you will not be able to
   use the 'rake solr:start' or 'rake solr:stop' commands with BibApp.
   However, you should still be able to use 'rake solr:refresh_index' to
   tell Solr to rebuild all the BibApp indexes.     
