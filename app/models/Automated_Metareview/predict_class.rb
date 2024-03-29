require 'Automated_Metareview/wordnet_based_similarity'
require 'Automated_Metareview/constants'

class PredictClass
=begin
 Identifies the probabilities of a review belonging to each of the three classes. 
 Returns an array of probablities (length = numClasses) 
=end
#predicting the review's class
def predict_classes(pos_tagger, core_NLP_tagger, review_text, review_graph, pattern_files_array, num_classes)
  p "!!!! Inside predict_classes method"
  #reading the patterns from the pattern files
  patterns_files = Array.new
  pattern_files_array.each do |file|
    patterns_files << file #collecting the file names for each class of patterns
  end
  
  tc = TextCollection.new
  single_patterns = Array.new(num_classes){Array.new}
  #reading the patterns from each of the pattern files
  for i in (0..num_classes - 1) #for every class
    #read_patterns in TextCollection helps read patterns in the format 'X = Y'
    single_patterns[i] = tc.read_patterns(patterns_files[i], pos_tagger) 
  end
  
  #Predicting the probability of the review belonging to each of the content classes
  #initializing variables
  wordnet = WordnetBasedSimilarity.new
  max_probability = 0.0
  class_value = 0          
  # edges = review_graph.edges #g.edges
  g = GraphGenerator.new
  # g.generate_graph(review_text, pos_tagger, core_NLP_tagger, false, false)
  # edges = g.edges  
  edges = review_graph.edges
  puts "~~~~~~review_edges inside predict_classes length #{edges.length}"
  class_prob = Array.new #contains the probabilities for each of the classes - it contains 3 rows for the 3 classes    
  #comparing each test review text with patterns from each of the classes
  for k in (0..num_classes - 1)
    #comparing edges with patterns from a particular class
    class_prob[k] = compare_review_with_patterns(edges, single_patterns[k], wordnet)/6.to_f #normalizing the result 
    #we divide the match by 6 to ensure the value is in the range of [0-1]     
  end #end of for loop for the classes          
  
  #printing the probability values
  puts("########## Probability for test review:: "+review_text[0]+" is::")  
  for k in (0..num_classes - 1)
    puts "class_prob[#{k}] .. #{class_prob[k]}"
  end         
  return class_prob
end #end of the prediction method
#------------------------------------------#------------------------------------------#------------------------------------------

def compare_review_with_patterns(single_edges, single_patterns, wordnet)
  final_class_sum = 0.0
  final_edge_num = 0
  single_edge_matches = Array.new(single_edges.length){Array.new}
  #resetting the average_match values for all the edges, before matching with the single_patterns for a new class
  for i in 0..single_edges.length - 1
    if(!single_edges[i].nil?)
      single_edges[i].average_match = 0
    end  
  end
  
  #comparing each single edge with all the patterns
  for i in (0..single_edges.length - 1)  #iterating through the single edges
    max_match = 0
    if(!single_edges[i].nil?)
      for j in (0..single_patterns.length - 1) 
        if(!single_patterns[j].nil?)
          single_edge_matches[i][j] = compare_edges(single_edges[i], single_patterns[j], wordnet)
          if(single_edge_matches[i][j] > max_match)
            max_match = single_edge_matches[i][j]
          end 
        end 
      end #end of for loop for the patterns
      single_edges[i].average_match = max_match  
      # #calculating average match
      # puts("Edge-Pattern Match:::")
      # count = 0
      # for j in (0..single_patterns.length - 1)
        # if(!single_patterns[j].nil?) #check ensures you dont add garbage values when no edge existed at "j"
          # puts(" - #{single_edge_matches[i][j]}")
          # single_edges[i].average_match = single_edges[i].average_match + single_edge_matches[i][j]
          # count+=1
        # end
      # end
        
      # puts("single_edges[i].averageMatch after:: #{single_edges[i].average_match}")
      # puts("count after:: #{count}")
        
      # if(count == 0) 
        # count = 1 #if matches with all patterns were 0 then count would remain 0 and result in a divide by zero error.
      # end
      
      # single_edges[i].average_match = single_edges[i].average_match/count
      # puts("******** MatchVal for single edge:: #{single_edges[i].in_vertex.name} - #{single_edges[i].out_vertex.name}:: #{single_edges[i].average_match}")
        
      #calculating class average
      if(single_edges[i].average_match != 0.0)
        final_class_sum = final_class_sum + single_edges[i].average_match
        #puts("finalClassSum:: #{final_class_sum}")
        final_edge_num+=1
      end

      puts("******************************************************************************************************")
    end #end of the if condition
  end #end of for loop
  
  # for i in (0..single_edges.length - 1) 
    # if(!single_edges[i].nil?)
      # for j in (0..single_patterns.length - 1) 
        # if(!single_patterns[j].nil?)
          # puts "comparing - #{single_edges[i].in_vertex.name} - #{single_edges[i].out_vertex.name} ..  #{single_patterns[j].in_vertex.name} - #{single_patterns[j].out_vertex.name}"
          # puts "labels - #{single_edges[i].label} ..  #{single_patterns[j].label}"
          # puts "single_edge_matches[#{i}][#{j}] .. #{single_edge_matches[i][j]}"
        # end
      # end
    # end
  # end
  
  if(final_edge_num == 0)
    final_edge_num = 1  
  end
  
  puts("final_class_sum:: #{final_class_sum} final_edge_num:: #{final_edge_num} Class average #{final_class_sum/final_edge_num}")
  return final_class_sum/final_edge_num #maxMatch
end #end of determineClass method
#------------------------------------------#------------------------------------------#------------------------------------------

def compare_edges(e1, e2, wordnet)
  speller = Aspell.new("en_US")
  speller.suggestion_mode = Aspell::NORMAL
  
  #matching in-in and out-out vertices    
  if(e1.nil?) 
    puts("e1 is null")
  end
  if(e2.nil?)
    puts("e2 is null")
  end
  
  avg_match_without_syntax = 0
  #compare edges so that only non-nouns or non-subjects are compared
  if(!e1.in_vertex.pos_tag.include?("NN") and !e1.out_vertex.pos_tag.include?("NN"))
    avg_match_without_syntax = (wordnet.compare_strings(e1.in_vertex, e2.in_vertex, speller) + 
                              wordnet.compare_strings(e1.out_vertex, e2.out_vertex, speller))/2.to_f
  elsif(!e1.in_vertex.pos_tag.include?("NN"))
    avg_match_without_syntax = wordnet.compare_strings(e1.in_vertex, e2.in_vertex, speller)
  elsif(!e1.out_vertex.pos_tag.include?("NN"))
    avg_match_without_syntax = wordnet.compare_strings(e1.out_vertex, e2.out_vertex, speller)
  end
  
  # puts("e1 label:: #{e1.label}")
  # puts("e2 label:: #{e2.label}")
  #only for without-syntax comparisons
  # avg_match_without_syntax = avg_match_without_syntax #/compare_labels(e1, e2) - ignore labels while predicting classes (since patterns are not assigned labels!)
  
  avg_match_with_syntax = 0
  puts("avg_match_without_syntax:: #{avg_match_without_syntax}")
    
  #matching in-out and out-in vertices
  if(!e1.in_vertex.pos_tag.include?("NN") and !e1.out_vertex.pos_tag.include?("NN"))
    avg_match_with_syntax = (wordnet.compare_strings(e1.in_vertex, e2.out_vertex, speller) + 
                              wordnet.compare_strings(e1.out_vertex, e2.in_vertex, speller))/2.to_f
  elsif(!e1.in_vertex.pos_tag.include?("NN"))
    avg_match_with_syntax = wordnet.compare_strings(e1.in_vertex, e2.out_vertex, speller)
  elsif(!e1.out_vertex.pos_tag.include?("NN"))
    avg_match_with_syntax = wordnet.compare_strings(e1.out_vertex, e2.in_vertex, speller)
  end
  
  # avg_match_with_syntax = (wordnet.compare_strings(e1.in_vertex, e2.out_vertex, speller) + 
                           # wordnet.compare_strings(e1.out_vertex, e2.in_vertex, speller))/2.to_f
  puts("avg_match_with_syntax:: #{avg_match_with_syntax}")
    
  if(avg_match_without_syntax > avg_match_with_syntax)
    return avg_match_without_syntax
  else
    return avg_match_with_syntax
  end
end #end of the compare_edges method
end