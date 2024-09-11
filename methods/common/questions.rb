
# Process questions (array of structs)

def process_questions(values)
  values['q_order'].each do |key|
    if values['verbose'] == true
      handle_output(values, "Information:\tProcessing value for #{key}")
    end
    if values['q_struct'][key].value == nil 
      handle_output(values, "Warning:\tValue for #{key} is NULL")
      quit(values)
    end
    correct = false
    if values['q_struct'][key].ask.match(/yes/)
      while correct == false do
        if values['q_struct'][key].value.match(/^get_/)
          new_value = values['q_struct'][key].value
          new_value = eval"[#{new_value}]"
          values['q_struct'][key].value = new_value.join
        end
        if values['defaults'] == false
          question = values['q_struct'][key].question+"? [ "+values['q_struct'][key].value+" ] "
          print question
          answer = $stdin.gets.chomp
        else
          answer = values['q_struct'][key].value
          evaluate_answer(key, answer, values)
          correct = true
        end
        if answer != ""
          if answer != values['q_struct'][key].value
            if values['q_struct'][key].valid.match(/[a-z,A-Z,0-9]/)
              if values['q_struct'][key].valid.match(/#{answer}/)
                correct = evaluate_answer(key, answer)
                if correct == true
                  values['q_struct'][key].value = answer
                end
              end
            else
              correct = evaluate_answer(key, answer, values)
              if correct == true
                values['q_struct'][key].value = answer
              end
            end
          else
            if correct == true
              values['q_struct'][key].value = answer
            end
          end
        else
          answer = values['q_struct'][key].value
          correct = evaluate_answer(key, answer, values)
          correct = true
        end
      end
    else
      if values['q_struct'][key].value.match(/^get_/)
        new_value = values['q_struct'][key].value
        new_value = eval"[#{new_value}]"
        values['q_struct'][key].value = new_value.join
      end
    end
  end
  return values
end

# Code to check answers

def evaluate_answer(key, answer, values)
  correct = false
  if values['q_struct'][key].eval != "no"
    new_value = values['q_struct'][key].eval
    if new_value.match(/^get|^set/)
      if new_value.match(/^get/)
        new_value = eval"[#{new_value}]"
        answer = new_value.join
        values['q_struct'][key].value = answer
      else
        values['q_struct'][key].value = answer
        eval"[#{new_value}]"
      end
      correct = true
    else
      correct = eval"[#{new_value}]"
      if correct == true
        values['q_struct'][key].value = answer
      end
    end
  else
    correct = true
  end
  answer = answer.to_s
  if values['verbose'] == true
    handle_output(values, "Information:\tSetting parameter #{key} to #{answer}")
  end
  return correct
end
