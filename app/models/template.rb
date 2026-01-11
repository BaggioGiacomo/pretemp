class Template < ApplicationRecord
  belongs_to :template_category, optional: true
end
