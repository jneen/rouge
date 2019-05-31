# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'xml.rb'

    class BIML < XML
      title "BIML"
      desc "BIML, Business Intelligence Markup Language"
      tag 'biml'
      filenames '*.biml'

      def self.detect?(text)
        return true if text =~ /<\s*Biml\b/
      end

      prepend :root do
        rule %r(<#\@\s*)m, Name::Tag, :directive_tag

        rule %r(<#[=]?\s*)m, Name::Tag, :directive_as_csharp
      end

      prepend :attr do
        #TODO: how to deal with embedded <# tags inside a attribute string
        #rule %r("<#[=]?\s*)m, Name::Tag, :directive_as_csharp
      end

      state :directive_as_csharp do
        rule /\s*#>\s*/m, Name::Tag, :pop!
        rule %r(.*?(?=\s*#>\s*))m do
          delegate CSharp
        end
      end

      state :directive_tag do
        rule RegexLexer::WHITESPACE_RE_MULTILINE, Text
        rule /[\w.:-]+\s*=/m, Name::Attribute, :attr
        rule /[\w]+\s*/m, Name::Attribute
        rule %r(/?\s*#>), Name::Tag, :pop!
      end
    end
  end
end
