class AutoNamespacing::AutoNamespacedComponent < Rbexy::Component
  def call
    tag.h1 "Hello auto-namespaced component"
  end
end
