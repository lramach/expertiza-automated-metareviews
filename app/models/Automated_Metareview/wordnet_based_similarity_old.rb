require 'Automated_Metareview/vertex'
require 'Automated_Metareview/constants'
require 'wordnet'
  
class WordnetBasedSimilarity
  attr_accessor :match, :count
  @@posTagger = EngTagger.new  
  def compare_strings(reviewVertex, submVertex)
    #include WordNet
    WordNet::WordNetDB.path = "/Users/lakshmi/Documents/Computer - workspaces et al/Add-ons/WordNet-3.0"
    
    speller = Aspell.new("en_US")
    speller.suggestion_mode = Aspell::NORMAL
  
    review = reviewVertex.name
    submission = submVertex.name
    reviewState = reviewVertex.state
    submState = submVertex.state
    
    puts("@@@@@@@@@ Comparing Vertices:: #{review} and #{submission} :: RevState:: #{reviewState} and SubmState:: #{submState}");
    @match = 0
    @count = 0
    
    reviewPOS = ""
    submPOS = ""
       
    if(review.casecmp(submission) == 0) # and !is_frequent_word(reviewVertex.name) - removing this condition else, it returns a NOMATCH although the frequent words are equal and this negatively impacts the total match value
      puts("Review vertex types #{reviewVertex.type} && #{submVertex.type}")   
      if(reviewState.equal?(submState) and reviewVertex.type.equal?(submVertex.type))
        @match = @match + EXACT
      elsif(!reviewState.equal?(submState) and reviewVertex.type.equal?(submVertex.type))
        @match = @match + NEGEXACT
      elsif(reviewState.equal?(submState) and !reviewVertex.type.equal?(submVertex.type))
        @match = @match + EXACT/2
      elsif(!reviewState.equal?(submState) and !reviewVertex.type.equal?(submVertex.type))
        @match = @match + NEGEXACT/2
      end
      puts("Found an exact match between vertices!")
      return @match
    end   
    
    stokRev = review.split(" ")
    #iterating through review tokens
    for i in (0..stokRev.length-1)
      revToken = stokRev[i].downcase()
      if(reviewPOS.empty?)#do not reset POS for every new token, it changes the POS of the vertex e.g. like has diff POS for vertices "like"(n) and "would like"(v)
        reviewPOS = determine_POS(reviewVertex).lstrip.rstrip
      end
      
      puts("*** RevToken:: #{revToken} ::Review POS:: #{reviewPOS} class #{reviewPOS.class}")
      if(revToken.equal?("n't"))
        revToken = "not"
        puts("replacing n't")
      end
      
      #if the review token is a frequent word, continue
      if(is_frequent_word(revToken))
        puts("Skipping frequent review token .. #{revToken}")
        next #equivalent of the "continue"
      end
      
      #fetching synonyms, hypernyms, hyponyms etc. for the review token       
      revTok = []
      revTok << revToken
      revStem = []
      revStem << find_stem_word(revToken, speller)     
      #fetching all the relations
      review_relations = get_relations_for_review_submission_tokens(revToken, revStem, reviewPOS)
      #setting the values in specific array variables
      revGloss = review_relations[0]
      revExam = review_relations[1]
      revSyn =review_relations[2]
      revHyper = review_relations[3]
      revHypo = review_relations[4]
      revMer = review_relations[5]
      revHol = review_relations[6]
      revAnt = review_relations[7]
      
      puts "reviewStem:: #{revStem} .. #{revStem.class}" 
      puts "reviewGloss:: #{revGloss} .. #{revGloss.class}"  
      puts "reviewExam:: #{revExam} .. #{revExam.class}" 
      puts "reviewSynonyms:: #{revSyn} .. #{revSyn.class}"
      puts "reviewHypernyms:: #{revHyper} .. #{revHyper.class}"
      puts "reviewHyponyms:: #{revHypo} .. #{revHypo.class}"
      puts "reviewMeronyms:: #{revMer} .. #{revMer.class}"
      puts "reviewHolonyms:: #{revHol} .. #{revHol.class}"
      puts "reviewAntonyms:: #{revAnt} .. #{revAnt.class}"
        
      stokSub = submission.split(" ")
      #iterating through submission tokens
      for i in (0..stokSub.length-1)
        subToken = stokSub[i].downcase()
        if(submPOS.empty?)#do not reset POS for every new token, it changes the POS of the vertex e.g. like has diff POS for vertices "like"(n) and "would like"(v)
          submPOS = determine_POS(submVertex).lstrip.rstrip
        end
        
        puts("*** SubToken:: #{subToken} ::Review POS:: #{submPOS}")
        if(subToken.equal?("n't"))
          subToken = "not"
          puts("replacing n't")
        end
        
        #if the review token is a frequent word, continue
        if(is_frequent_word(subToken))
          puts("Skipping frequent subtoken .. #{subToken}")
          next #equivalent of the "continue"
        end
                    
        #fetching synonyms, hypernyms, hyponyms etc. for the submission token
        submTok = []       
        submTok << subToken
        submStem = []
        submStem << find_stem_word(subToken, speller)
        subm_relations = get_relations_for_review_submission_tokens(subToken, submStem, submPOS)
        submGloss = subm_relations[0]
        submExam = subm_relations[1]
        submSyn =subm_relations[2]
        submHyper = subm_relations[3]
        submHypo = subm_relations[4]
        submMer = subm_relations[5]
        submHol = subm_relations[6]
        submAnt = subm_relations[7]  
        puts "submStem:: #{submStem}"        
        puts "submGloss:: #{submGloss}"
        puts "submGloss:: #{submExam}"
        puts "submSynonyms:: #{submSyn}"
        puts "submHypernyms:: #{submHyper}"
        puts "submHyponyms:: #{submHypo}"
        puts "submMeronyms:: #{submMer}"
        puts "submHolonyms:: #{submHol}"
        puts "submAntonyms:: #{submAnt}" 
          
        #------------------------------------------
        #checks are ordered from BEST to LEAST degree of semantic relatedness
        #*****exact matches 
        # puts "@match #{@match} reviewState #{reviewState} submState #{submState} reviewPOS #{reviewPOS} submPOS #{submPOS}"  
        # puts "reviewState.equal?(submState) #{reviewState.equal?(submState)}"
        # puts "reviewPOS.equal?(submPOS) #{reviewPOS == submPOS}"     
        if(subToken.casecmp(revToken) == 0 or submStem[0].casecmp(revStem[0]) == 0) #EXACT MATCH (submission.toLowerCase().equals(review.toLowerCase()))
          puts("exact match for #{revToken} & #{subToken} or #{submStem[0]} and #{revStem[0]}")
          if(reviewState.equal?(submState) and reviewPOS == submPOS)
            @match = @match + EXACT
          elsif(!reviewState.equal?(submState) and reviewPOS == submPOS)
            @match = @match + NEGEXACT
          elsif(reviewState.equal?(submState) and reviewPOS != submPOS)
            @match = @match + EXACT/2
          elsif(!reviewState.equal?(submState) and reviewPOS != submPOS)
            @match = @match + NEGEXACT/2
          end
          @count+=1
          next #skip all remaining checks
        end #end of if condition checking for exact matches
        #------------------------------------------
        #*****For Synonyms
        #if the method returns 'true' it indicates a synonym match of some kind was found and the remaining checks can be skipped
        if(check_match(revTok, submTok, revSyn, submSyn, revStem, submStem, reviewState, submState, SYNONYM, ANTONYM))
          next
        end
        #------------------------------------------
        #ANTONYMS
        if(check_match(revTok, submTok, revAnt, submAnt, revStem, submStem, reviewState, submState, ANTONYM, SYNONYM))
          next
        end
        #------------------------------------------
        #*****For Hypernyms
        if(check_match(revTok, submTok, revHyper, submHyper, revStem, submStem, reviewState, submState, HYPERNYM, NEGHYPERNYM))
          puts "**** after hyperym match #{@match} - #{@count}"
          next
        end
        #------------------------------------------   
        #*****For Hyponyms
        if(check_match(revTok, submTok, revHypo, submHypo, revStem, submStem, reviewState, submState, HYPONYM, NEGHYPONYM))
          puts "**** after hyponym match #{@match} - #{@count}"
          next
        end
        #------------------------------------------
        #*****For Meronyms
        if(check_match(revTok, submTok, revMer, submMer, revStem, submStem, reviewState, submState, MERONYM, NEGMERONYM))
          puts "**** after hyponym match #{@match} - #{@count}"
          next
        end
        #------------------------------------------
        #*****For Holonyms
        if(check_match(revTok, submTok, revHol, submHol, revStem, submStem, reviewState, submState, HOLONYM, NEGHOLONYM))
          puts "**** after hyponym match #{@match} - #{@count}"
          next
        end       
        #------------------------------------------ 
        #overlap across definitions   
        if(!revGloss.nil? and !submGloss.nil?)
          if(overlap(revGloss, submGloss) > 0)
            if(reviewState == submState)
              @match = @match + OVERLAPDEFIN
            elsif(reviewState != submState)
              @match = @match + NEGOVERLAPDEFIN
            end
            @count+=1
            next
          end
        end
        #------------------------------------------
        #overlap across examples
        if(!revExam.nil? and !submExam.nil?)
          if(overlap(revExam, submExam) > 0)
            if(reviewState == submState)
              @match = @match + OVERLAPEXAM
            elsif(reviewState != submState)
              @match = @match + NEGOVERLAPEXAM
            end
            @count+=1
            next
          end
        end
        #------------------------------------------  
        #no match found!
        puts "No Match found!"
        @match = @match + NOMATCH
        @count+=1
      end #end of the for loop for submission tokens 
      #puts "@match outside #{@match}"
    end #end of the for loop for review tokens
    
    if(@count > 0)
      puts ("Match: #{@match} Count:: #{@count}")
      puts("@@@@@@@@@ Returning Value: #{(@match.to_f/@count.to_f).round}")
      return (@match.to_f/@count.to_f).round #an average of the matches found
    end
    puts("@@@@@@@@@ Returning NOMATCH")
    return NOMATCH
    
  end #end of compareStrings method
  
#------------------------------------------------------------------------------
=begin
 This method fetches the synonyms, hypernyms, hyponyms and other relations for the 'token' and its stem 'stem'.
 This is done for both review and submission tokens/stems.
 It returns a double dimensional array, where each element is an array of synonyms, hypernyms etc. 
=end

def get_relations_for_review_submission_tokens(token, stem, pos)
  relations = Array.new
  lemmas = WordNet::WordNetDB.find(token)
  if(lemmas.nil?)
    lemmas = WordNet::WordNetDB.find(stem[0]) 
  end
  #select the lemma corresponding to the token's POS
  lemma = ""
  lemmas.each do |l|
    puts "lemma's POS :: #{l.pos} and POS :: #{pos}"
    if(l.pos.casecmp(pos) == 0)
      lemma = l
    end  
  end
      
  puts "Selected lemma :: #{lemma}"      
  #error handling for lemmas's without synsets that throw errors! (likely due to the dictionary file we are using)
  begin #error handling
  #if selected reviewLemma is not nil or empty
  if(!lemma.nil? and lemma != "" and !lemma.synsets.nil?)      
    #creating arrays of all the values for synonyms, hyponyms etc. for the review token
    for g in 0..lemma.synsets.length - 1
      #fetching the first review synset
      lemma_synset = lemma.synsets[g]
      if(!lemma_synset.gloss.nil?)
        relations << extract_definition(lemma_synset.gloss)#0
      else
        relations << nil
      end
      if(!lemma_synset.gloss.nil?)
        relations << extract_examples(lemma_synset.gloss)#1
      else
        relations << nil
      end
          
      #looking for all relations synonym, hypernym, hyponym etc. from among this synset
      #synonyms
      lemmaSyns = lemma_synset.get_relation("&")
      if(!lemmaSyns.nil? and lemmaSyns.length != 0)
        #for each synset get the values and add them to the array
        for h in 0..lemmaSyns.length - 1
          relations << lemmaSyns[h].words#2
        end
      else
        #puts "synonyms are nil"
        relations << nil #setting nil when no synset match is found for a particular type of relation
      end
      #hypernyms
      lemmaHypers = lemma_synset.get_relation("@")#hypernym.words
      if(!lemmaHypers.nil? and lemmaHypers.length != 0)
        #for each synset get the values and add them to the array
        for h in 0..lemmaHypers.length - 1
          relations << lemmaHypers[h].words#3
        end
      else
        #puts "hypernyms are nil"
        relations << nil
      end
      #hyponyms
      lemmaHypos = lemma_synset.get_relation("~")#hyponym
      if(!lemmaHypos.nil? and lemmaHypos.length != 0)
        #for each synset get the values and add them to the array
        for h in 0..lemmaHypos.length - 1
          relations << lemmaHypos[h].words#4
        end
      else
        #puts "hyponyms are nil"
        relations << nil
      end
      #meronym
      lemmaMeros = lemma_synset.get_relation("%p")
      if(!lemmaMeros.nil? and lemmaMeros.length != 0)
        #for each synset get the values and add them to the array
        for h in 0..lemmaMeros.length - 1
          relations << lemmaMeros[h].words#5
        end
      else
        #puts "meronyms are nil"
        relations << nil
      end
      #holonyms
      lemmaHolos = lemma_synset.get_relation("#p")
      if(!lemmaHolos.nil? and lemmaHolos.length != 0)
        #for each synset get the values and add them to the array
        for h in 0..lemmaHolos.length - 1
          relations << lemmaHolos[h].words#6
        end
      else
        #puts "holonyms are nil"
        relations << nil
      end
      #antonyms
      lemmaAnts = lemma_synset.get_relation("!")
      if(!lemmaAnts.nil? and lemmaAnts.length != 0)
        #for each synset get the values and add them to the array
        for h in 0..lemmaAnts.length - 1
          relations << lemmaAnts[h].words#7
        end
      else
        #puts "antonyms are nil"
        relations << nil
      end
    end  
  end #end of checking if the lemma is nil or empty
  rescue
    puts "The lemma doesn't have any synsets"
  end
  
  return relations
end

#------------------------------------------------------------------------------
=begin
 This method compares the submission and reviews' synonyms and antonyms with each others' tokens and stem values.
 The instance variables 'match' and 'count' are updated accordingly. 
=end
def check_match(rev_token, subm_token, rev_arr, subm_arr, rev_stem, subm_stem, rev_state, subm_state, match_type, non_match_type)
  flag = 0 #indicates if a match was found
  puts("check_match between: #{rev_token} & #{subm_token} match_type #{match_type} and non_match_type #{non_match_type}")
  #puts rev_arr
  puts "rev_arr #{rev_arr}"
  #puts "!rev_arr.nil? and !subm_arr.nil? #{!rev_arr.nil?} and #{!subm_arr.nil?}"
  if((!rev_arr.nil? and !subm_arr.nil? and compare_arrays(rev_arr, subm_arr)) or (!rev_arr.nil? and (compare_arrays(rev_arr, subm_token) or compare_arrays(rev_arr, subm_stem))) or 
    (!subm_arr.nil? and (compare_arrays(subm_arr, rev_token) or compare_arrays(subm_arr, rev_stem))))          
    puts("Match found between: #{rev_token} & #{subm_token}")
    flag = 1 #setting the flag to indicate that a match was found
    if(rev_state == subm_state)
      @match = @match + match_type
    elsif(rev_state != subm_state)
      @match = @match+ non_match_type
    end
    puts("@@ Match: #{@match}")
    @count+=1
  end
  if(flag == 1)
    return true
  else
    return false
  end
end
 
#------------------------------------------------------------------------------
=begin
 This method compares the submission and reviews' hypernyms, hyponyms, meronyms and holonyms with each others' tokens and stem values.
 The instance variables 'match' and 'count' are updated accordingly. 
=end
# def check_hyper_hypo_mero_holonyms(rev_token, subm_token, rev_arr, subm_arr, rev_stem, subm_stem, rev_state, subm_state, match_type, non_match_type)
  # flag = 0 #to indicate if a match is found in this method or not
  # if((!rev_arr.nil? and !subm_arr.nil? and compare_arrays(rev_arr, subm_arr)) or (!rev_arr.nil? and (compare_arrays(rev_arr, subm_token) or compare_arrays(rev_arr, subm_stem))) or 
    # (!subm_arr.nil? and (compare_arrays(subm_arr, rev_token) or compare_arrays(subm_arr, rev_stem))))
    # flag = 1          
    # puts("Match of type #{match_type} found between: #{rev_token} & #{subm_token}")
    # if(rev_state == subm_state)
      # @match = @match + match_type #updating match value
    # elsif(rev_state != subm_state)
      # @match = @match + non_match_type
    # end
    # puts("@@ Match: #{@match}")
    # @count+=1 #updating counter
  # end
  # if(flag == 1)
    # return true
  # else
    # return false
  # end
# end

#------------------------------------------------------------------------------

def compare_arrays(arrs1, arrs2)
  #puts "inside compare_arrays"
  arrs1.each{
    |arr1|
    arrs2.each{
      |arr2|
      #puts "comparing #{arr1} & #{arr2}"
      if(arr1.downcase == arr2.downcase) #include?
        #puts "return true"
        return true
      end
    }
  }
  return false
end

#------------------------------------------------------------------------------

=begin
 determine_POS - method helps identify the POS tag (for the wordnet lexicon) for a certain word 
=end
def determine_POS(vert)
  str_pos = vert.pos_tag
  puts("Inside determine_POS POS Tag:: #{str_pos}")
  if(str_pos.include?("CD") or str_pos.include?("NN") or str_pos.include?("PR") or str_pos.include?("IN") or str_pos.include?("EX") or str_pos.include?("WP"))
    pos = "n"#WordNet::Noun
  elsif(str_pos.include?("JJ"))
    pos = "a" #WordNet::Adjective
  elsif(str_pos.include?("TO") or str_pos.include?("VB") or str_pos.include?("MD"))
    pos = "v" #WordNet::Verb
  elsif(str_pos.include?("RB"))
    pos = "r" #WordNet::Adverb
  else
    pos = "n" #WordNet::Noun
  end
  #puts("Part of Speech:: #{pos}")
  return pos
end
#------------------------------------------------------------------------------  
=begin
 'is_stop_word' method checks to see if the word is a stop word or frequently used word  
=end
def is_stop_word(word)
  #constants con = new constants();
  #removing any (, ), [, ] in the string 
  word.gsub!("(", "") #gsub replaces all occurrences of "(" and the exclamation point helps to do in-place substitution
  word.gsub!(")", "") #if the character doesn't exist, the function returns nil, which does not affect the existing variable
  word.gsub!("[", "")
  word.gsub!("]", "")
  word.gsub!("\"", "")
  
  #checking for closed class words
  for i in (0..CLOSED_CLASS_WORDS.length-1) #(int i = 0; i < constants.CLOSED_CLASS_WORDS.length; i++)
    if(word.casecmp(CLOSED_CLASS_WORDS[i]) == 0)
      return true
    end
  end      
  
  #checking for stopwords
  for i in (0..STOP_WORDS.length-1) #(int i = 0; i < constants.STOP_WORDS.length; i++)
    if(word.casecmp(STOP_WORDS[i]) == 0)
      return true
    end    
    return false    
  end
end
#------------------------------------------------------------------------------      
=begin
  is_frequent_word - method checks to see if the given word is a frequent word
=end
def is_frequent_word(word)
  #checking if the word is a frequent word
  for i in (0..FREQUENT_WORDS.length-1)
    #puts FREQUENT_WORDS[i]
    if(word.casecmp(FREQUENT_WORDS[i]) == 0)
      return true
    end
  end
  return false
end #end of is_frequent_word method
#------------------------------------------------------------------------------
=begin
  find_stem_word - stems the word and checks if the word is correctly spelt, else it will return a correctly spelled word as suggested by spellcheck
  It generated the nearest stem, since no context information is involved, the quality of the stems may not be great!
=end
def find_stem_word(word, speller)
  stem = word.stem
  #puts "stem inside find_stem_word #{stem}"
  
  correct = stem #initializing correct to the stem word
  #checkiing the stem word's spelling for correctness
  while(!speller.check(correct)) do
    if(!speller.suggest(correct).first.nil?)
      correct = speller.suggest(correct).first
    else
      #break out of the loop, else it will continue infinitely
      break #break out of the loop if the first correction was nil
    end
  end
  #puts "**** stem for #{word} is #{correct}"  
  return correct
end #end of is_frequent_word method

end #end of WordnetBasedSimilarity class

#------------------------------------------------------------------------------
=begin
 This method is used to extract definitions for the words (since glossed contain definitions and examples!)
 glosses - string containing the gloss of the synset 
=end
def extract_definition(glosses)
  #puts "***** Inside extract_definition"
  definitions = []
  #extracting examples from definitions
  temp = glosses
  tempList = temp.split(";")
  for i in 0..tempList.length - 1
    if(!tempList[i].include?('"'))
      definitions << tempList[i]
    end
  end
  #puts definitions
  return definitions
end

#------------------------------------------------------------------------------
def extract_examples(glosses) #glosses is a single gloss with possibly many examples
  #puts "***** Inside extract_examples"
  examples = []  
  #extracting examples from definitions
  temp = glosses
  tempList = temp.split(";")
  for i in 0..tempList.length - 1
    #puts " printing #{tempList[i]}"
    if(tempList[i].include?('"'))
      examples << tempList[i]
    end
  end
  #puts examples
  return examples
end

#------------------------------------------------------------------------------

def overlap(def1, def2)
  speller = Aspell.new("en_US")
  speller.suggestion_mode = Aspell::NORMAL
  instance = WordnetBasedSimilarity.new
  numOverlap = 0
  #only overlaps across the ALL definitions
  # puts "def1.length #{def1.length}"
  # puts "def2.length #{def2.length}"
  
  #iterating through def1's definitions
  for i in 0..def1.length-1
    if(!def1[i].nil?)
      #puts "def1[#{i}] #{def1[i]}"
      def1[i].gsub!("\"", " ")
      if(def1[i].include?(";"))
        def1[i] = def1[i][0..def1[i].index(";")]
      end
      #iterating through def2's definitions
      for j in 0..def2.length - 1   
        if(!def2[j].nil?)
          if(def2[j].include?(";"))
            def2[j] = def2[j][0..def2[j].index(";")]
          end
          #puts "def2[#{j}] #{def2[j]}"
          s1 = def1[i].split(" ")
          s1.each do |tok1|
            tok1stem = find_stem_word(tok1, speller)
            s2 = def2[j].split(" ")
            s2.each do |tok2|
              tok2stem = find_stem_word(tok2, speller)
              # puts "tok1 #{tok1} and tok2 #{tok2}"
              # puts "tok1stem #{tok1stem} and tok2stem #{tok2stem}"
              if((tok1.downcase == tok2.downcase or tok1stem.downcase == tok2stem.downcase) and !instance.is_stop_word(tok1))
                puts("**Overlap def/ex:: #{tok1}")
                numOverlap+=1
              end
            end #end of s2 loop
          end #end of s1 loop
        end #end of def2[j][0] being null
      end #end of for loop for def2 - j
    end #end of if def1[i][0] being null
  end #end of for loop for def1 - i
  puts "numOverlap #{numOverlap}"
  return numOverlap
end
#------------------------------------------------------------------------------
    
# instance = WordnetBasedSimilarity.new
# v1 =  Vertex.new("version-control", 1, 1, 0, 1, 1, "NN")
# v2 =  Vertex.new("gives", 1, 1, 0, 1, 1, "JJ")
# instance.compare_strings(v1, v2)

#puts "vertex name #{instance.name}"
#puts instance.is_stop_word("that")

# instance.find_stem_word("fallacies")
# instance.find_stem_word("plagued")
# instance.find_stem_word("played")
# instance.find_stem_word("playful")
# instance.find_stem_word("running")

#puts instance.is_stop_word("hello")
# index = WordNet::NounIndex.instance
# lemma = index.find("presentation")
# syns = lemma.synsets
# glo1 = syns[1].gloss
# glo2 = syns[2].gloss
# puts glo1
# puts glo2
# overlap(extract_definition(glo1),extract_definition(glo2)) 
#extract_examples(glo)


# def readFileAndWrite (filename)
  # words1 = []
  # words2 = []
  # results = []
#   
  # instance = WordnetBasedSimilarity.new
  # #reading the words
  # FasterCSV.foreach(filename) do |row|
    # puts row[0]
    # text = row[0].to_s
    # word1 = text[0..text.index("-")-2] 
    # word2 = text[text.index("-")+2..text.length-1]
    # puts "words - #{word1} && #{word2}"
    # words1 << word1
    # words2 << word2
    # v1 = Vertex.new(word1, 1, 1, 0, 1, 1, "NN")
    # v2 = Vertex.new(word2, 1, 1, 0, 1, 1, "NN")
    # results << instance.compareStrings(v1, v2)
  # end
#   
  # #writing results to a file
  # FasterCSV.open("/Users/lakshmi/Documents/Thesis/wordsim353-ruby/set4_353_results.csv", "w") do |csvWriter|
    # for i in 0..words1.length - 1
      # puts "#{words1[i]} - #{words2[i]} :: #{results[i]}"
      # csvWriter << [words1[i], words2[i], results[i]]
    # end
  # end
# end
# require 'faster_csv'
# readFileAndWrite("/Users/lakshmi/Documents/Thesis/wordsim353-ruby/set4_353_test.csv")





