dir = File.dirname(__FILE__)
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)

# = Sass (Syntactically Awesome StyleSheets)
#
# Sass is a meta-language on top of CSS
# that's used to describe the style of a document
# cleanly and structurally,
# with more power than flat CSS allows.
# Sass both provides a simpler, more elegant syntax for CSS
# and implements various features that are useful
# for creating manageable stylesheets.
#
# == Features 
#
# * Whitespace active
# * Well-formatted output
# * Elegant input
# * Feature-rich
#
# == Using Sass
#
# Sass can be used in two ways:
# As a plugin for Ruby on Rails
# and as a standalone parser.
# Sass is bundled with Haml,
# so if the Haml plugin or RubyGem is installed,
# Sass will already be installed as a plugin or gem, respectively.
#
# To install Haml and Sass as a Ruby on Rails plugin,
# use the normal Rails plugin installer:
#
#   ./script/plugin install http://svn.hamptoncatlin.com/haml/tags/stable
#
# Sass templates in Rails don't quite function in the same way as views,
# because they don't contain dynamic content,
# and so only need to be compiled when the template file has been updated.
# By default (see options, below),
# ".sass" files are placed in public/stylesheets/sass.
# Then, whenever necessary, they're compiled into corresponding CSS files in public/stylesheets.
# For instance, public/stylesheets/sass/main.sass would be compiled to public/stylesheets/main.css.
#
# Using Sass in Ruby code is very simple.
# First install the Haml/Sass RubyGem:
#
#   gem install haml
#
# Then you can use it by including the "sass" gem
# and using Sass::Engine like so:
#
#   engine = Sass::Engine.new("#main\n  :background-color #0000ff")
#   engine.render #=> "#main { background-color: #0000ff; }\n"
#
# == CSS Rules
#
# Rules in flat CSS have two elements:
# the selector
# (e.g. "#main", "div p", "li a:hover")
# and the attributes
# (e.g. "color: #00ff00;", "width: 5em;").
#
# Sass has both of these,
# as well as one additional element: nested rules.
#
# === Rules and Selectors
#
# However, some of the syntax is a little different.
# The syntax for selectors is the same,
# but instead of using brackets to delineate the attributes that belong to a particular rule,
# Sass uses two spaces of indentation.
# For example:
#
#   #main p
#     <attribute>
#     <attribute>
#     ...
#
# === Attributes
#
# There are two different ways to write CSS attrbibutes.
# The first is very similar to the how you're used to writing them:
# with a colon between the name and the value.
# However, Sass attributes don't have semicolons at the end;
# each attribute is on its own line, so they aren't necessary.
# For example:
#
#   #main p
#     color: #00ff00
#     width: 97%
#
# is compiled to:
#
#   #main p {
#     color: #00ff00;
#     width: 97% }
#
# The second syntax for attributes is slightly different.
# The colon is at the beginning of the attribute,
# rather than between the name and the value,
# so it's easier to tell what elements are attributes just by glancing at them.
# For example:
#
#   #main p
#     :color #00ff00
#     :width 97%
#
# is compiled to:
#
#   #main p {
#     color: #00ff00;
#     width: 97% }
#
# === Nested Rules
#
# Rules can also be nested within each other.
# This signifies that the inner rule's selector is a child of the outer selector.
# For example:
#
#   #main p
#     :color #00ff00
#     :width 97%
#
#     .redbox
#       :background-color #ff0000
#       :color #000000
#
# is compiled to:
#
#   #main p {
#     color: #00ff00;
#     width: 97%; }
#     #main p .redbox {
#       background-color: #ff0000;
#       color: #000000; }
#
# This makes insanely complicated CSS layouts with lots of nested selectors very simple:
#
#   #main
#     :width 97%
#     
#     p, div
#       :font-size 2em
#       a
#         :font-weight bold
#         
#     pre
#       :font-size 3em
#
# is compiled to:
#
#   #main {
#     width: 97%; }
#     #main p, #main div {
#       font-size: 2em; }
#       #main p a, #main div a {
#         font-weight: bold; }
#     #main pre {
#       font-size: 3em; }
#
# === Referencing Parent Rules
#
# In addition to the default behavior of inserting the parent selector
# as a CSS parent of the current selector
# (e.g. above, "#main" is the parent of "p"),
# you can have more fine-grained control over what's done with the parent selector
# by using the ampersand character "&" in your selectors.
#
# The ampersand is automatically replaced by the parent selector,
# instead of having it prepended.
# This allows you to cleanly create pseudo-attributes:
#
#   a
#     :font-weight bold
#     :text-decoration none
#     &:hover
#       :text-decoration underline
#     &:visited
#       :font-weight normal
#
# Which would become:
#
#   a {
#     font-weight: bold;
#     text-decoration: none; }
#     a:hover {
#       text-decoration: underline; }
#     a:visited {
#       font-weight: normal; }
#
# It also allows you to add selectors at the base of the hierarchy,
# which can be useuful for targeting certain styles to certain browsers:
#
#   #main
#     :width 90%
#     #sidebar
#       :float left
#       :margin-left 20%
#       .ie6 &
#         :margin-left 40%
#
# Which would become:
#
#   #main {
#     width: 90%; }
#     #main #sidebar {
#       float: left;
#       margin-left: 20%; }
#       .ie6 #main #sidebar {
#         margin-left: 40%; }
#
# === Attribute Namespaces
#
# CSS has quite a few attributes that are in "namespaces;"
# for instance, "font-family," "font-size," and "font-weight"
# are all in the "font" namespace.
# In CSS, if you want to set a bunch of attributes in the same namespace,
# you have to type it out each time.
# Sass offers a shortcut for this:
# just write the namespace one,
# then indent each of the sub-attributes within it.
# For example:
#
#   .funky
#     :font
#       :family fantasy
#       :size 30em
#       :weight bold
#
# is compiled to:
#
#   .funky {
#     font-family: fantasy;
#     font-size: 30em;
#     font-weight: bold; }
#
# == Constants
#
# Sass has support for setting document-wide constants.
# They're set using an exclamation mark followed by the name,
# an equals sign, and the value.
# An attribute can then be set to the value of a constant
# by following it with another equals sign.
# For example:
#
#   !main_color = #00ff00
#
#   #main
#     :color = !main_color
#     :p
#       :background-color = !main_color
#       :color #000000
#
# is compiled to:
#
#   #main {
#     color: #00ff00; }
#     #main p {
#       background-color: #00ff00;
#       color: #000000; }
#
# === Arithmetic
#
# You can even do basic arithmetic with constants.
# Sass recognizes numbers, colors,
# lengths (numbers with units),
# and strings (everything that's not one of the above),
# and various operators that work on various values.
# All the normal arithmetic operators
# (+, -, *, /, %, and parentheses for grouping)
# are defined as usual
# for numbers, colors, and lengths.
# The "+" operator is also defined for Strings
# as the concatenation operator.
# For example:
#
#   !main_width = 10
#   !unit1 = em
#   !unit2 = px
#   !bg_color = #a5f39e
#
#   #main
#     :background-color = !bg_color
#     p
#       :background-color = !bg_color + #202020
#       :width = !main_width + !unit1
#     img.thumb
#       :width = (!main_width + 15) + !unit2
#
# is compiled to:
#
#   #main {
#     background-color: #a5f39e; }
#     #main p {
#       background-color: #c5ffbe;
#       width: 10em; }
#     #main img.thumb {
#       width: 25em; }
#
# === Colors
#
# Colors may be written as three- or six-digit hex numbers prefixed
# by a pound sign (#), or as HTML4 color names. For example,
# "#ff0", "#ffff00" and "yellow" all refer to the same color.
#
# Not only can arithmetic be done between colors and other colors,
# but it can be done between colors and normal numbers.
# In this case, the operation is done piecewise one each of the
# Red, Green, and Blue components of the color.
# For example:
#
#   !main_color = #a5f39e
#
#   #main
#     :background-color = !main_color
#     p
#       :background-color = !main_color + 32
#
# is compiled to:
#
#   #main {
#     background-color: #a5f39e; }
#     #main p {
#       background-color: #c5ffbe; }
#
# === Strings
#
# Strings are the type that's used by default
# when an element in a bit of constant arithmetic isn't recognized
# as another type of constant.
# However, they can also be created explicitly be wrapping a section of code with quotation marks.
# Inside the quotation marks,
# a backslash can be used to
# escape quotation marks that you want to appear in the CSS.
# For example:
#
#   !content = "Hello, \"Hubert\" Bean."
#
#   #main
#     :content = "string(" + !content + ")"
#
# is compiled to:
#
#   #main {
#     content: string(Hello, "Hubert" Bean.) }
#
# === Default Concatenation
#
# All those plusses and quotes for concatenating strings
# can get pretty messy, though.
# Most of the time, if you want to concatenate stuff,
# you just want individual values with spaces in between them.
# Thus, in Sass, when two values are next to each other without an operator,
# they're simply joined with a space.
# For example:
#
#   !font_family = "sans-serif"
#   !main_font_size = 1em
#
#   #main
#     :font
#       :family = !font_family
#       :size = !main_font_size
#     h6
#       :font = italic "small-caps" bold (!main_font_size + 0.1em) !font_family
#
# is compiled to:
#
#   #main {
#     font-family: sans-serif;
#     font-size: 1em; }
#     #main h6 {
#       font: italic small-caps bold 1.1em sans-serif; }
#
# == Directives
#
# Directives allow the author to directly issue instructions to the Sass compiler.
# They're prefixed with an at sign, "<tt>@</tt>",
# followed by the name of the directive,
# a space, and any arguments to it -
# just like CSS directives.
# For example:
#
#   @import red.sass
#
# === Import
#
# Currently, the only directive is the "import" directive.
# It works in a very similar way to the CSS import directive,
# and sometimes compiles to a literal CSS "@import".
#
# Sass can import either other Sass files or plain CSS files.
# If it imports a Sass file,
# not only are the rules from that file included,
# but all constants in that file are made available in the current file.
#
# Sass looks for other Sass files in the working directory,
# and the Sass file directory under Rails.
# Additional search directories may be specified
# using the :load_paths option (see below).
#
# Sass can also import plain CSS files.
# In this case, it doesn't literally include the content of the files;
# rather, it uses the built-in CSS "@import" directive to tell the client program
# to import the files.
#
# The import directive can take either a full filename
# or a filename without an extension.
# If an extension isn't provided,
# Sass will try to find a Sass file with the given basename in the load paths,
# and, failing that, will assume a relevant CSS file will be available.
#
# For example,
#
#   @import foo.sass
#
# would compile to
#
#   .foo
#     :color #f00
#
# whereas
#
#   @import foo.css
#
# would compile to
#
#   @import foo.css
#
# Finally,
#
#  @import foo
#
# might compile to either,
# depending on whether a file called "foo.sass" existed.
#
# == Comments
#
# === Silent Comments
#
# It's simple to add "silent" comments,
# which don't output anything to the CSS document,
# to a Sass document.
# Simply use the familiar C-style notation for a one-line comment, "//",
# at the normal indentation level and all text following it won't be output.
# For example:
#
#   // A very awesome rule.
#   #awesome.rule
#     // An equally awesome attribute.
#     :awesomeness very
#
# becomes
#
#   #awesome.rule {
#     awesomeness: very; }
#
# === Loud Comments
#
# "Loud" comments are just as easy as silent ones.
# These comments output to the document as CSS comments,
# and thus use the same opening sequence: "/*".
# For example:
#
#   /* A very awesome rule.
#   #awesome.rule
#     /* An equally awesome attribute.
#     :awesomeness very
#
# becomes
#
#   /* A very awesome rule. */
#   #awesome.rule {
#     /* An equally awesome attribute. */
#     awesomeness: very; }
#
# == Output Style
#
# Although the default CSS style that Sass outputs is very nice,
# and reflects the structure of the document in a similar way that Sass does,
# sometimes it's good to have other formats available.
#
# Sass allows you to choose between three different output styles
# by setting the <tt>:style</tt> option.
# In Rails, this is done by setting <tt>Sass::Plugin.options[:style]</tt>;
# outside Rails, it's done by passing an options hash with </tt>:style</tt> set.
#
# === <tt>:nested</tt>
#
# Nested style is the default Sass style,
# because it reflects the structure of the document
# in much the same way Sass does.
# Each attribute has its own line,
# but the indentation isn't constant.
# Each rule is indented based on how deeply it's nested.
# For example:
#
#   #main {
#     color: #fff;
#     background-color: #000; }
#     #main p {
#       width: 10em; }
#
#   .huge {
#     font-size: 10em;
#     font-weight: bold;
#     text-decoration: underline; }
#
# Nested style is very useful when looking at large CSS files
# for the same reason Sass is useful for making them:
# it allows you to very easily grasp the structure of the file
# without actually reading anything.
#
# === <tt>:expanded</tt>
#
# Expanded is the typical human-made CSS style,
# with each attribute and rule taking up one line.
# Attributes are indented within the rules,
# but the rules aren't indented in any special way.
# For example:
#
#   #main {
#     color: #fff;
#     background-color: #000;
#   }
#   #main p {
#     width: 10em;
#   }
#
#   .huge {
#     font-size: 10em;
#     font-weight: bold;
#     text-decoration: underline;
#   }
#
# === <tt>:compact</tt>
#
# Compact style, as the name would imply,
# takes up less space than Nested or Expanded.
# However, it's also harder to read.
# Each CSS rule takes up only one line,
# with every attribute defined on that line.
# Nested rules are placed next to each other with no newline,
# while groups of rules have newlines between them.
# For example:
#
#   #main { color: #fff; background-color: #000; }
#   #main p { width: 10em; }
#
#   .huge { font-size: 10em; font-weight: bold; text-decoration: underline; } 
#
# == Sass Options
#
# Options can be set by setting the hash <tt>Sass::Plugin.options</tt>
# from <tt>environment.rb</tt> in Rails,
# or by passing an options hash to Sass::Engine.
# Available options are:
#
# [<tt>:style</tt>]             Sets the style of the CSS output.
#                               See the section on Output Style, above.
#
# [<tt>:always_update</tt>]     Whether the CSS files should be updated every
#                               time a controller is accessed,
#                               as opposed to only when the template has been modified.
#                               Defaults to false.
#                               Only has meaning within Ruby on Rails.
#                               
# [<tt>:always_check</tt>]      Whether a Sass template should be checked for updates every
#                               time a controller is accessed,
#                               as opposed to only when the Rails server starts.
#                               If a Sass template has been updated,
#                               it will be recompiled and will overwrite the corresponding CSS file.
#                               Defaults to false if Rails is running in production mode,
#                               true otherwise.
#                               Only has meaning within Ruby on Rails.
#
# [<tt>:template_location</tt>] The directory where Sass templates should be read from.
#                               Defaults to <tt>RAILS_ROOT + "/public/stylesheets/sass"</tt>.
#                               Only has meaning within Ruby on Rails.
#
# [<tt>:css_location</tt>]      The directory where CSS output should be written to.
#                               Defaults to <tt>RAILS_ROOT + "/public/stylesheets"</tt>.
#                               Only has meaning within Ruby on Rails.
#
# [<tt>:filename</tt>]          The filename of the file being rendered.
#                               This is used solely for reporting errors,
#                               and is automatically set when using Rails.
#
# [<tt>:load_paths</tt>]        An array of filesystem paths which should be searched
#                               for Sass templates imported with the "@import" directive.
#                               This defaults to the working directory and, in Rails,
#                               whatever <tt>:template_location</tt> is
#                               (by default <tt>RAILS_ROOT + "/public/stylesheets/sass"</tt>).
# 
module Sass; end

require 'sass/engine'
