require 'csv'

CSV.generate do |csv|
  column_names = %w(name age)
  csv << column_names
  @results.each do |result|
    column_values = [
      "a",
      "b"
    ]
    csv << column_values
  end
end
