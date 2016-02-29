
require 'yaml'
require 'pp'

input = ARGV[0]

# h = YAML::load(File::open("../data/2016_02_19/15_23_23_adonis-9/Data15_23_23.yaml").read)
h = YAML::load(File::open(input).read)

t = []
t2 = []
head = []

h.first[0].each {|key, value| head.push key } 
head.push :time_per_pixel

h.each {|key, value| 
  t2 = []
  key.each { |key2, value2|
    t2.push value2
  }
  t2.push value
  t.push t2
}

# sorted = t.sort{ |a,b| (a[0] <=> b[0]) == 0 ? (a[1] <=> b[1]) == 0 ? (a[2] <=> b[2]) == 0 ? (a[3] <=> b[3]) == 0 ? a[4] ? a[5] ? 1 : 0 : 1 : (a[3] <=> b[3])  : (a[2] <=> b[2]) : (a[1] <=> b[1]) : (a[0] <=> b[0]) }

File::open("/tmp/test.csv", "w"){ |f|
  f.puts head.collect{ |v| v }.join(", ")
  t.each{ |e|
    f.puts e.collect{ |v| v }.join(", ")
  }
}
