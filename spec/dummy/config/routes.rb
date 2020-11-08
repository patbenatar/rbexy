Rails.application.routes.draw do
  get "custom_provider" => "custom_provider#index"
  get "rbx_view" => "rbx_view#index"
  get "perf_test", to: "perf_test#index"
end
