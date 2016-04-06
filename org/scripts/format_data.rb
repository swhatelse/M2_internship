
require 'yaml'
require 'pp'
require 'csv'
input = ARGV[0]

t = []
t2 = []
head = []

# h = YAML::load(File::open(input).read)
h = YAML::load_documents(File::open(input).read){ |doc|

  if head.empty?
    # h.first[0].each {|key, value| head.push key }
    doc.first[0].each {|key, value| head.push key } 
    head.push :time_per_pixel
  end

  # h.each {|key, value| 
  doc.each {|key, value| 
    t2 = []
    key.each { |key2, value2|
      t2.push value2
    }
    t2.push value
    t.push t2
  }
}

CSV.open("/tmp/test.csv", "w"){ |f|
  f << head
  t.each{ |e|
    f << e
  }
}
