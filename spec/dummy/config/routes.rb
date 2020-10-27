Rails.application.routes.draw do
  get "custom_provider" => "custom_provider#index"
  get "perf_test", to: "perf_test#index"
end
