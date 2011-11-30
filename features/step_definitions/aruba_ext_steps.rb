Then /^the file "([^"]*)" should contain:$/ do |file, content|
  check_file_content(file, content, true)
end
