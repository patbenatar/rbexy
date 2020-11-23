module Rbexy
  class SimpleLexer
    class SyntaxError < StandardError
      def initialize(lexer)
        super(
          "Invalid syntax: `#{lexer.scanner.peek(20)}`\n" +
          "Stack: #{lexer.stack}\n" +
          "Tokens: #{lexer.tokens}"
        )
      end
    end

    Patterns = HashMash.new(
      open_expression: /{/,
      close_expression: /}/,
      expression_content: /[^}{"'<]+/,
      open_tag_def: /<(?!\/)/,
      open_tag_end: /<\//,
      close_tag: /\s*\/?>/,
      close_self_closing_tag: /\s*\/>/,
      tag_name: /\/?[A-Za-z0-9\-_.]+/,
      text_content: /[^<{#]+/,
      comment: /^\p{Blank}*#.*(\n|\z)/,
      whitespace: /\s+/,
      attr: /[A-Za-z0-9\-_\.:]+/,
      open_attr_splat: /{\*\*/,
      attr_assignment: /=/,
      double_quote: /"/,
      single_quote: /'/,
      double_quoted_text_content: /[^"]+/,
      single_quoted_text_content: /[^']+/,
      expression_internal_tag_prefixes: /(\s+(&&|\?|:|do|do\s*\|[^\|]+\||{|{\s*\|[^\|]+\|)\s+\z|\A\s*\z)/,
      declaration: /<![^>]*>/
    )

    # TODO: move this to the component resolver? maybe Rbexy always runs its
    # default resolver first, and only delegates to the user injected one if
    # we don't match a valid html element? or the default resolver + prefixes
    # is enough to work for most cases, that if you want to override you subclass
    # or implement the whole thing and being smart about html elements is up to you...
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

    attr_reader :stack, :tokens, :scanner

    def initialize(code)
      @stack = [:raw]
      @tokens = []
      @scanner = StringScanner.new(code)
    end

    def tokenize
      until scanner.eos?
        case stack.last
        when :raw
          # if unescaped {
            # push curr_raw if non-empty
            # EXPRESSION
          # if unescaped < that resolves to component?
            # push curr_raw if non-empty
            # COMPONENT
          # else
            # add to curr_raw
        else
          raise SyntaxError, self
        end
      end

      tokens
    end
  end
end
