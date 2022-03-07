# Generated via
#  `rails generate hyrax:work GenericWork`
module Hyrax
  # Generated form for GenericWork
  class GenericWorkForm < Hyrax::Forms::WorkForm
    puts 'generic worker formmmmmmmmmmmmmmmmmmmmm'
    self.model_class = ::GenericWork
    self.terms += [:resource_type]
  end
end
