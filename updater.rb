require 'redcarpet'
require 'aws-sdk'
require 'erb'
SOURCE_BUCKET_NAME = 'ofl-markdown-source'

markdown_options = {
  autolink: true,
  tables: true,
  filter_html: false,
  with_toc_data: true,
  prettify: true,
  strikethrough: true,
  underline: true,
  footnotes: true
}

article_template = ERB.new File.read("article.html.erb")
index_template = ERB.new File.read("index.html.erb")

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,autolink: true,tables: true,filter_html: false,with_toc_data: true,prettify: true)

s3 = Aws::S3::Client.new
resp = s3.list_objects(bucket: SOURCE_BUCKET_NAME)

all_files = []

resp.contents.each do |object|
  puts "#{object.key} #=> #{object.etag}"
  key_comps = object.key.split(".")
  key_comps.pop
  page_title = key_comps.join(".")
  key_comps.push("html")
  html_filename = key_comps.join(".").downcase
  
  markdown_file = s3.get_object(bucket: SOURCE_BUCKET_NAME, key: object.key)
  markdown_data = markdown_file.body.read
  html_data = markdown.render(markdown_data)
  b = binding
  template_data = article_template.result b
  s3.put_object(bucket: 'ofuklol.com', key: html_filename, body: template_data,acl: "public-read")
  File.open(File.join("preview",html_filename),'w') { |f| f.write(template_data) }
  all_files << html_filename
  puts "Uploaded #{html_filename}"
end

b = binding
index_data = index_template.result b
s3.put_object(bucket: 'ofuklol.com', key: 'index.html', body: index_data,acl: "public-read")
File.open(File.join("preview","index.html"),'w') { |f| f.write(index_data) }

