module Rbexy
  module ArrayFindMap
    refine Array do
      def find_map
        lazy.map { |i| yield(i) }.reject(&:nil?).first
      end
    end
  end

  class ComponentResolver
    using ArrayFindMap

    KNOWN_HTML_ELEMENTS = %w(
      a abbr acronym address animate animateMotion animateTransform applet area article aside audio b base basefont
      bdi bdo bgsound big blink blockquote body br button canvas caption center circle cite clipPath code col colgroup
      color-profile command content data datalist dd defs del desc details dfn dialog dir discard div dl dt element
      ellipse em embed feBlend feColorMatrix feComponentTransfer feComposite feConvolveMatrix feDiffuseLighting
      feDisplacementMap feDistantLight feDropShadow feFlood feFuncA feFuncB feFuncG feFuncR feGaussianBlur feImage
      feMerge feMergeNode feMorphology feOffset fePointLight feSpecularLighting feSpotLight feTile feTurbulence
      fieldset figcaption figure filter font footer foreignObject form frame frameset g h1 h2 h3 h4 h5 h6 hatch
      hatchpath head header hgroup hr html i iframe image img input ins isindex kbd keygen label legend li line
      linearGradient link listing main map mark marker marquee mask menu menuitem mesh meshgradient meshpatch meshrow
      meta metadata meter mpath multicol nav nextid nobr noembed noframes noscript object ol optgroup option output p
      param path pattern picture plaintext polygon polyline pre progress q radialGradient rb rect rp rt rtc ruby s
      samp script section select set shadow slot small solidcolor source spacer span stop strike strong style sub
      summary sup svg switch symbol table tbody td template text textarea textPath tfoot th thead time title tr track
      tspan tt u ul unknown use var video view wbr xmp
    ).to_set

    attr_reader :component_namespaces

    def initialize
      self.component_namespaces = {}
    end

    def component_namespaces=(hash)
      @component_namespaces = hash.transform_keys(&:to_s)
    end

    def component?(name, template)
      return false if KNOWN_HTML_ELEMENTS.include?(name)
      return true if component_class(name, template)
      false
    end

    def component_class(name, template)
      possible_names = matching_namespaces(template).map { |ns| "#{ns}.#{name}" } << name
      possible_names.find_map(&method(:find))
    end

    private

    def find(name)
      find!(name)
    rescue NameError => e
      raise e unless e.message =~ /wrong constant name/ || e.message =~ /uninitialized constant/
      nil
    end

    def matching_namespaces(template)
      component_namespaces.select { |path, ns| template.identifier.start_with?(path) }.values.flatten.uniq
    end

    def find!(name)
      ActiveSupport::Inflector.constantize("#{name.gsub(".", "::")}Component")
    end
  end
end
