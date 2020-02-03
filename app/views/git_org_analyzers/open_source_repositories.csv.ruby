csv_headers = [
  "Repository Name",
  "Languages",
  "Created At"
]
CSV.generate(headers: csv_headers, write_headers: true) do |csv|
  @repository_details[:repositories].each do |repository|
    csv << [
      repository[:repository_name],
      repository[:repository_languages],
      repository[:created_at]
    ]
  end
end
