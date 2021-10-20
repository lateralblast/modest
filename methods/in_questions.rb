
# Process questions (array of structs)

def process_questions(options)
  options['q_order'].each do |key|
    if options['verbose'] == true
      handle_output(options,"Information:\tProcessing value for #{key}")
    end
    if options['q_struct'][key].value == nil 
      handle_output(options,"Warning:\tValue for #{key} is NULL")
      quit(options)
    end
    correct = false
    if options['q_struct'][key].ask.match(/yes/)
      while correct == false do
        if options['q_struct'][key].value.match(/^get_/)
          new_value = options['q_struct'][key].value
          new_value = eval"[#{new_value}]"
          options['q_struct'][key].value = new_value.join
        end
        if options['defaults'] == false
          question = options['q_struct'][key].question+"? [ "+options['q_struct'][key].value+" ] "
          print question
          answer = $stdin.gets.chomp
        else
          answer = options['q_struct'][key].value
          evaluate_answer(key,answer,options)
          correct = true
        end
        if answer != ""
          if answer != options['q_struct'][key].value
            if options['q_struct'][key].valid.match(/[a-z,A-Z,0-9]/)
              if options['q_struct'][key].valid.match(/#{answer}/)
                correct = evaluate_answer(key,answer)
                if correct == true
                  options['q_struct'][key].value = answer
                end
              end
            else
              correct = evaluate_answer(key,answer,options)
              if correct == true
                options['q_struct'][key].value = answer
              end
            end
          else
            if correct == true
              options['q_struct'][key].value = answer
            end
          end
        else
          answer = options['q_struct'][key].value
          correct = evaluate_answer(key,answer,options)
          correct = true
        end
      end
    else
      if options['q_struct'][key].value.match(/^get_/)
        new_value = options['q_struct'][key].value
        new_value = eval"[#{new_value}]"
        options['q_struct'][key].value = new_value.join
      end
    end
  end
  return options
end

# Code to check answers

def evaluate_answer(key,answer,options)
  correct = false
  if options['q_struct'][key].eval != "no"
    new_value = options['q_struct'][key].eval
    if new_value.match(/^get|^set/)
      if new_value.match(/^get/)
        new_value = eval"[#{new_value}]"
        answer = new_value.join
        options['q_struct'][key].value = answer
      else
        options['q_struct'][key].value = answer
        eval"[#{new_value}]"
      end
      correct = true
    else
      correct = eval"[#{new_value}]"
      if correct == true
        options['q_struct'][key].value = answer
      end
    end
  else
    correct = true
  end
  answer = answer.to_s
  if options['verbose'] == true
    handle_output(options,"Information:\tSetting parameter #{key} to #{answer}")
  end
  return correct
end
