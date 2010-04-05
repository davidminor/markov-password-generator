# Generate english-like words using markov chains (or other language depending on dictionary)
DICTIONARY_FILE = '/usr/share/dict/words'

def usage
  puts "ruby generate_password.rb WORD_LENGTH [NUM_TO_GENERATE]"
  exit
end

usage if ( ARGV.length != 1 && ARGV.length != 2 )
word_length, word_count = ARGV[0].to_i, (ARGV[1] || 1).to_i
usage if ( word_length < 3 || word_count < 1 )

base = "a"[0]

# Compute probabilities of 3 letter sequences (could be computed once and stored for reading)
probs = Array.new(27) { |i| Array.new(27) { |j| Array.new(27) { |k| 0 }}}
pen_probs = Array.new(27) { |i| Array.new(27) { |j| Array.new(27) { |k| 0 }}}
last_probs = Array.new(27) { |i| Array.new(27) { |j| Array.new(27) { |k| 0 }}}

# Count each sequence of 3 specific letters
File.open( DICTIONARY_FILE ) do |file|
  file.each_line do |line|
    next if line.length < 5
    next if line !~ /^[a-zA-Z]+$/
    prev = [ 26, 26 ] # 26 indicates no letter
    prob_arr = [probs]*(line.chomp!.length - 2) + [pen_probs, last_probs]
    line.downcase.each_byte do |c|
      c -= base
      prob_arr.shift[prev[-2]][prev[-1]][c] += 1
      prev << c
    end
  end
end

# normalize
[ probs, pen_probs, last_probs ].each do |prob_arr|
  prob_arr.each do |second_letter|
    second_letter.each do |third_letter|
      sum = third_letter.inject(0) { |s,count| s += count }
      third_letter.map! { |count| count.to_f()/sum } if sum > 0
    end
  end
end

srand( Time.now.to_i )
word_count.times do

  chars = []
  ([probs]*(word_length-2) + [pen_probs, last_probs]).each do |prob_arr|
    total = 0
    target = rand
    prob_arr[chars[-2] || 26][chars[-1] || 26].each_with_index do |prob,char|
      total += prob
      if ( total >= target )
        chars << char
        break
      end
    end
  end
  
  redo if ( chars.length < word_length ) #probs occasionally leads to shorter words

  puts chars.map { |c| (c+base).chr }.join
end
