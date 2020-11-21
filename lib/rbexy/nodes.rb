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

      # KNOWN_BOOLEAN_ATTRIBUTES = ActionView::Helpers::TagHelper::BOOLEAN_ATTRIBUTES
      # %(#{key}="#{key}")
      KNOWN_VOID_ELEMENTS = ActionView::Helpers::TagHelper::TagBuilder::VOID_ELEMENTS
      # if VOID_ELEMENTS.include?(name) && content.nil?
      #   "<#{name.to_s.dasherize}#{tag_options(options, escape_attributes)}>".html_safe
      # else
      #   content_tag_string(name.to_s.dasherize, content || "", options, escape_attributes)
      # end

      def initialize(name, members, children)
        @name = name
        @members = members || []
        @children = children
      end

      def compile
        if KNOWN_HTML_ELEMENTS.include?(name)
          compiled_children = children.map { |c| "\#{#{c.compile}}" }.join
          "%Q(<#{name}>#{compiled_children}</#{name}>).html_safe"
          # attrs = compile_members_to_s
          # if KNOWN_VOID_ELEMENTS.include?(name) && children.length == 0
          #   "\"<#{name}#{attrs}>\".html_safe"
          # elsif children.length == 0
          #   "\"<#{name}#{attrs} />\".html_safe"
          # else
            # "\"<#{name}#{attrs}>\".html_safe + #{children.map(&:compile).join(" + ")} + \"</#{name}>\".html_safe"
          # end
        else
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
      end

      def compile_members_to_s
        return "" unless members.length > 0

        " " + members.map do |member|
          case member
          when ExpressionGroup
            # TODO
          when SilentNewline
            member.compile
          else
            member.compile_to_s
            # result << "#{member.compile},"
          end
        end.join(" + ")
      end

      def compile_members
        members.each_with_object("") do |member, result|
          case member
          when ExpressionGroup
            result << "**#{member.compile},"
          when SilentNewline
            result << member.compile
          else
            result << "#{member.compile_to_h},"
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

      def compile_to_h
        "\"#{name}\": #{value.compile}"
      end

      def compile_to_s
        "\"#{name}=\" + #{value.compile}"
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
