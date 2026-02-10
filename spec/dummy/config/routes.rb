Rails.application.routes.draw do
  root "dummy#index"
  mount HayaSelectHelpers::Engine => "/haya_select_helpers"
  get "*path", to: "dummy#index", constraints: ->(request) { request.format.html? }
end
