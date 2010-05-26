# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

#### Register METS as XML MIME Type, so we can provide RESTful METS ####
Mime::Type.register_alias "text/xml", :mets

#### Register RDF as XML MIME Type, so we can provide RESTful RDF ####
Mime::Type.register_alias "text/xml", :rdf

