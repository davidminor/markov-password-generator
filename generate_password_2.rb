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

#Keep an array of frequencies of final letter for each two letter group, e.g.
# "ab" => [["n", 5], ["s", 3] ... ]
def increment(prob_hash, key)
  di = key[0,2]
  freq_arr = prob_hash[di]
  if !freq_arr
    prob_hash[di] = [[key[-1,1], 1]]
  else
    target_letter = key[-1,1]
    freq = freq_arr.assoc(target_letter)
    if !freq then freq_arr << [target_letter, 1] else freq[1] += 1 end
  end
end

probs, pen_probs, last_probs = nil, nil, nil

if (!PROBABILITY_FILE || !File.exist?(PROBABILITY_FILE) )
  
  # Compute probabilities of 3 letter sequences
  probs, pen_probs, last_probs = {}, {}, {}

  # Count each sequence of 3 specific letters
  File.open( DICTIONARY_FILE ) do |file|
    MATCHING_LINE = /^[a-zA-Z]{4,}$/
    file.each_line do |line|
      if line !~ MATCHING_LINE then next else line = "  " + line.chomp.downcase end
      ([probs]*(line.size-4) + [pen_probs, last_probs]).zip(line.scan(/(?=(...))/).flatten).each {|n| increment(*n)}
    end
  end

  #Convert to running sum for binary search
  prob_hashes = [probs, pen_probs, last_probs]
  prob_hashes.each do |prob_hash|
    prob_hash[:totals] = {}
    prob_hash.each_pair do |di, freq_arr|
      next if di == :totals
      total = 0
      freq_arr.sort! { |a,b| b[1] <=> a[1] }
      freq_arr.each { |entry| total += entry[1]; entry[1] = total }
      prob_hash[:totals][di] = total
    end
  end
  
  Marshal.dump([probs, pen_probs, last_probs], File.new(PROBABILITY_FILE, "wb")) if (PROBABILITY_FILE)
  
else
  probs, pen_probs, last_probs = *Marshal.load(File.open(PROBABILITY_FILE, "rb"))
end

word_count.times do
  chars = "  "
  ([probs]*(word_length-2) + [pen_probs, last_probs]).each do |prob_hash|
    di = chars[-2,2]
    freq_arr = prob_hash[di]
    break if !freq_arr || freq_arr.size == 0
    target = rand(prob_hash[:totals][di]) + 1
    chars << freq_arr.find { |x| x[1] >= target }[0]
  end
  
  redo if chars.size - 2 != word_length
  puts chars.lstrip
end
