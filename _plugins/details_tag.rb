require "jekyll"

class DetailsTag < Liquid::Tag

def initialize(tag_name, markup, tokens)
    super
    @caption = markup
end

def render(context)
    site = context.registers[:site]
    converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
    # below Jekyll 3.x use this:
    # converter = site.getConverterImpl(::Jekyll::Converters::Markdown)
    caption = converter.convert(@caption).gsub(/<\/?p[^>]*>/, '').chomp
    body = converter.convert(super(context))
    "<details><summary>#{caption}</summary>#{body}</details>"
end

Liquid::Template.register_tag "details", self
end
   
  