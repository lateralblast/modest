# frozen_string_literal: true

# Process questions (array of structs)

def process_questions(values)
  values['order'].each do |key|
    information_message(values, "Processing value for #{key}")
    if values['answers'][key].value.nil?
      warning_message(values, "Value for #{key} is NULL")
      quit(values)
    end
    correct = false
    if values['answers'][key].ask.match(/yes/)
      while correct == false
        if values['answers'][key].value.match(/^get_/)
          new_value = values['answers'][key].value
          new_value = eval "[#{new_value}]"
          values['answers'][key].value = new_value.join
        end
        if values['defaults'] == false
          question = "#{values['answers'][key].question}? [ #{values['answers'][key].value} ] "
          print question
          answer = $stdin.gets.chomp
        else
          answer = values['answers'][key].value
          evaluate_answer(key, answer, values)
          correct = true
        end
        if answer != ''
          if answer != values['answers'][key].value
            if values['answers'][key].valid.match(/[a-z,A-Z,0-9]/)
              if values['answers'][key].valid.match(/#{answer}/)
                correct = evaluate_answer(key, answer)
                values['answers'][key].value = answer if correct == true
              end
            else
              correct = evaluate_answer(key, answer, values)
              values['answers'][key].value = answer if correct == true
            end
          elsif correct == true
            values['answers'][key].value = answer
          end
        else
          answer = values['answers'][key].value
          correct = evaluate_answer(key, answer, values)
          correct = true
        end
      end
    elsif values['answers'][key].value.match(/^get_/)
      new_value = values['answers'][key].value
      new_value = eval "[#{new_value}]"
      values['answers'][key].value = new_value.join
    end
  end
  values
end

# Code to check answers

def evaluate_answer(key, answer, values)
  correct = false
  if values['answers'][key].eval != 'no'
    new_value = values['answers'][key].eval
    if new_value.match(/^get|^set/)
      if new_value.match(/^get/)
        new_value = eval "[#{new_value}]"
        answer = new_value.join
        values['answers'][key].value = answer
      else
        values['answers'][key].value = answer
        eval "[#{new_value}]"
      end
      correct = true
    else
      correct = eval "[#{new_value}]"
      values['answers'][key].value = answer if correct == true
    end
  else
    correct = true
  end
  answer = answer.to_s
  information_message(values, "Setting parameter #{key} to #{answer}")
  correct
end
