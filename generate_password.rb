# Generate english-like words using markov chains (or other language depending on dictionary)
DICTIONARY_FILE = '/usr/share/dict/words'

# Set this to a file name to store the probabilities for better repeat performance
PROBABILITY_FILE = nil # '~/.generate_password_cache'

def usage
  puts "ruby generate_password.rb WORD_LENGTH [NUM_TO_GENERATE]"
  exit
end

usage if ( ARGV.length != 1 && ARGV.length != 2 )
word_length, word_count = ARGV[0].to_i, (ARGV[1] || 1).to_i
usage if ( word_length < 3 || word_count < 1 )

base = "a"[0]

probs, pen_probs, last_probs = nil, nil, nil

if (!PROBABILITY_FILE || !File.exist?(PROBABILITY_FILE) )
  
  # Compute probabilities of 3 letter sequences
  make_arr = lambda { Array.new(27) { |i| Array.new(27) { |j| Array.new(27) { |k| 0 }}} }
  probs, pen_probs, last_probs = make_arr[], make_arr[], make_arr[]

  # Count each sequence of 3 specific letters
  File.open( DICTIONARY_FILE ) do |file|
    MATCHING_LINE = /^[a-zA-Z]{4,}$/
    file.each_line do |line|
      next if line !~ MATCHING_LINE
      prev = [ 26, 26 ] # 26 indicates no letter
      prob_arrs = [probs]*(line.chomp!.length - 2) + [pen_probs, last_probs]
      line.downcase.each_byte { |c| prob_arr.shift[prev[-2]][prev[-1]][(prev << (c-base))[-1]] += 1 }
    end
  end

  # normalize
  prob_arrs = [ probs, pen_probs, last_probs ]
  prob_arrs.each do |prob_arr|
    prob_arr.each do |second_letter|
      second_letter.each do |third_letter|
        sum = third_letter.inject(0) { |s,count| s += count }
        third_letter.map! { |count| count.to_f()/sum } if sum > 0
      end
    end
  end
  
  Marshal.dump(prob_arrs, File.new(PROBABILITY_FILE, "wb")) if (PROBABILITY_FILE)
  
else
  probs, pen_probs, last_probs = *Marshal.load(File.open(PROBABILITY_FILE, "rb"))
end

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
