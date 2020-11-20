module Rbexy
  module Nodes
    module Util
      def self.safe_string(str)
        str.gsub('"', '\\"')
      end

      def self.safe_tag_name(name)
        name.gsub(".", "__")
      end
    end

    class Template
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def compile
        "#{children.map(&:compile).map { |c| "@output_buffer << rbexy_prep_output(#{c})"}.join(";")};@output_buffer"
      end
    end

    class Text
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        "\"#{Util.safe_string(content)}\""
      end
    end

    class ExpressionGroup
      attr_reader :statements

      def initialize(statements)
        @statements = statements
      end

      def compile
        statements.map(&:compile).join
      end
    end

    class Expression
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        content
      end
    end

    class XmlNode
      attr_reader :name, :members, :children

      KNOWN_HTML_ELEMENTS = %w[
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
      ]

      def initialize(name, members, children)
        @name = name
        @members = members || []
        @children = children
      end

      def compile
        base_tag = "rbexy_tag.#{Util.safe_tag_name(name)}(#{compile_members})"
        tag = if children.length > 0
          [
            "#{base_tag} { capture {",
              children.map(&:compile).map { |c| "@output_buffer << rbexy_prep_output(#{c})" }.join(";"),
            "} }"
          ].join
        else
          base_tag
        end + ".html_safe"

        if Rbexy.configuration.enable_context
          [
            "(",
              "rbexy_context.push({});",
              "#{tag}.tap { rbexy_context.pop }",
            ")"
          ].join
        else
          tag
        end
      end

      def compile_members
        members.each_with_object("") do |member, result|
          case member
          when ExpressionGroup
            result << "**#{member.compile},"
          when SilentNewline
            result << member.compile
          else
            result << "#{member.compile},"
          end
        end
      end
    end

    class XmlAttr
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def compile
        "\"#{name}\": #{value.compile}"
      end
    end

    class SilentNewline
      def compile
        "\n"
      end
    end

    class Declaration
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        "\"#{Util.safe_string(content)}\".html_safe"
      end
    end
  end
end
