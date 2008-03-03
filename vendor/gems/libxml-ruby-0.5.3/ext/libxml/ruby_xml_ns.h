/* $Id: ruby_xml_ns.h 225 2007-12-07 04:58:09Z transami $ */

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_XML_NS__
#define __RUBY_XML_NS__

extern VALUE cXMLNS;

typedef struct ruby_xml_ns {
  xmlNsPtr ns;
  int is_ptr;
  VALUE xd;
} ruby_xml_ns;

void ruby_xml_ns_free(ruby_xml_ns *rxn);
void ruby_init_xml_ns(void);
VALUE ruby_xml_ns_new(VALUE class, VALUE xd, xmlNsPtr ns);
VALUE ruby_xml_ns_new2(VALUE class, VALUE xd, xmlNsPtr ns);
VALUE ruby_xml_ns_name_get(VALUE self);
#endif
