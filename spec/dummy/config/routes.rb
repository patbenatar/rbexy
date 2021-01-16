Rails.application.routes.draw do
  get "rbx_view" => "rbx_view#index"
  get "controller_context" => "context#index"
  get "perf_test", to: "perf_test#index"
  get "utf8", to: "rbx_view#utf8"
  get "caching/inline", to: "caching#inline"
  get "caching/component", to: "caching#component"
  get "caching/call_component", to: "caching#call_component"
  get "caching/partial_render", to: "caching#partial_render"
end
