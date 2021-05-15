class PerfTestController < ActionController::Base
  layout false

  helper_method :time

  def index
  end

  def time
    times = 100.times.map do
      start = Time.now
      yield
      (Time.now.to_f - start.to_f) * 1000
    end

    avg_duration = (times.sum.to_f / times.count).round(5)

    "<div>Avg time (ms): #{avg_duration}</div>".html_safe
  end
end
