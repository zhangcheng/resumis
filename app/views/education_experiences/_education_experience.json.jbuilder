json.extract! education_experience, :id, :school_name, :diploma, :description, :start_date, :end_date, :created_at, :updated_at
json.url education_experience_path(education_experience, format: :json)