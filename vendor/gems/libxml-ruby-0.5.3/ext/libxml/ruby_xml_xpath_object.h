/* $Id $ */

#ifndef __RUBY_XML_XPATH_OBJECT__
#define __RUBY_XML_XPATH_OBJECT__

extern VALUE cXMLXPathObject;

typedef struct ruby_xml_xpath_object_s {
  xmlXPathObjectPtr xpop;
} ruby_xml_xpath_object;

VALUE ruby_xml_xpath_object_wrap(xmlXPathObjectPtr xpop);

VALUE ruby_xml_xpath_object_to_a(VALUE self);
VALUE ruby_xml_xpath_object_first(VALUE self);
VALUE ruby_xml_xpath_object_set(VALUE self);
VALUE ruby_xml_xpath_object_empty_q(VALUE self);
VALUE ruby_xml_xpath_object_each(VALUE self);
VALUE ruby_xml_xpath_object_first(VALUE self);
VALUE ruby_xml_xpath_object_length(VALUE self);
VALUE ruby_xml_xpath_object_set_type(VALUE self);
VALUE ruby_xml_xpath_object_string(VALUE self);

void ruby_xml_xpath_object_mark(xmlXPathObjectPtr xpop);
void ruby_xml_xpath_object_free(xmlXPathObjectPtr xpop);

void ruby_init_xml_xpath_object(void);

#endif
