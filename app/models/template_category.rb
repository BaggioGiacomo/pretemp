class TemplateCategory < ApplicationRecord
  has_many :templates, dependent: :destroy
end
