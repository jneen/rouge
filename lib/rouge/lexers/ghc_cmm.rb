# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class GHCCmm < RegexLexer
      title "GHC Cmm (C--)"
      desc "Intermediate representation of the GHC Haskell compiler."
      tag 'ghc-cmm'
      filenames '*.cmm', '*.dump-cmm', '*.dump-cmm-*'

      ws = %r(\s|//.*?\n|/[*].*?[*]/)
      id = %r([\w#\$%_']+)

      state :root do
        rule %r/\s+/m, Text

        # sections markers
        rule %r/^=====.*=====$/, Generic::Heading
        # timestamps
        rule %r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+ UTC$/, Comment::Single

        rule %r/(?=section\s+)/ do
          push :section
        end

        mixin :preprocessor_macros

        mixin :comments
        mixin :literals
        mixin :operators_and_keywords

        # Function: `name /* optional whitespace */ (`
        # Function (arguments via explicit stack handling): `name /* optional whitespace */ {`
        rule %r{(?=
                  #{id}
             #{ws}*
                  [\{\(]
                )}mx do
          push :function
        end

        mixin :types
        mixin :infos
        mixin :names

        # rest is Text
        rule %r/./, Text
      end

      state :section do
        rule %r/section/, Keyword
        rule %r/"(data|cstring|text|rodata|relrodata|bss)"/, Name::Builtin

        rule %r/{/, Punctuation, :pop!

        mixin :names
        mixin :operators_and_keywords

        rule %r/\s/, Text
      end

      state :preprocessor_macros do
        rule %r/#include|#endif|#else|#if/, Comment::Preproc

        rule %r{
            (\#define)
            (#{ws}*)
            (#{id})
          }mx do |m|
          token Comment::Preproc, m[1]
          recurse m[2]
          token Name::Label, m[3]
        end
      end

      state :comments do
        rule %r/\/{2}.*/, Comment::Single
        rule %r/\(likely.*?\)/, Comment
        rule %r/\/\*.*?\*\//m, Comment::Multiline
      end

      state :literals do
        rule %r/-?[0-9]+/, Literal::Number::Integer
        rule %r/"/, Literal::String::Delimiter, :literal_string
      end

      state :literal_string do
        # quotes
        rule %r/\\./, Literal::String::Escape
        rule %r/%./, Literal::String::Symbol
        rule %r/"/, Literal::String::Delimiter, :pop!
        rule %r/./, Literal::String
      end

      state :operators_and_keywords do
        rule %r/\.\./, Operator
        rule %r/[+\-*\/<>=!&|~]/, Operator
        rule %r/(::)(#{ws}*)([A-Z]\w+)/ do |m|
          token Operator, m[1]
          recurse m[2]
          token Keyword::Type, m[3]
        end

        rule %r/[\[\].{}:;,()]/, Punctuation
        rule %r/const/, Keyword::Constant
        rule %r/"/, Literal::String::Double

        rule %r/(switch)([^{]*)({)/ do |m|
          token Keyword, m[1]
          recurse m[2]
          token Punctuation, m[3]
        end

        rule %r/(returns)(#{ws}*)(to)/ do |m|
          token Keyword, m[1]
          recurse m[2]
          token Keyword, m[3]
        end

        rule %r/(never)(#{ws}*)(returns)/ do |m|
          token Keyword, m[1]
          recurse m[2]
          token Keyword, m[3]
        end

        rule %r{return(?=(#{ws}*)\()}, Keyword
        rule %r{(if|else|goto|call|offset|import|jump|ccall|foreign|prim|case|unwind)(?=#{ws})}, Keyword
        rule %r{(export|reserve|push)(?=#{ws})}, Keyword
        rule %r{(default)(?=#{ws}*:)}, Keyword
      end

      state :function do
        rule %r/INFO_TABLE_FUN|INFO_TABLE_CONSTR|INFO_TABLE_SELECTOR|INFO_TABLE_RET|INFO_TABLE/, Name::Builtin
        rule %r/%#{id}/, Name::Builtin
        rule %r/#{id}/, Name::Function
        rule %r/\s+/, Text
        rule %r/[({]/, Punctuation, :pop!
        mixin :comments
      end

      state :types do
        # Memory access: `type[42]`
        # Note: Only a token for type is produced.
        rule %r/(#{id})(?=\[[^\]])/ do |m|
          token Keyword::Type, m[1]
        end

        # Array type: `type[]`
        rule %r/(#{id}\[\])/ do |m|
          token Keyword::Type, m[1]
        end

        # Type in variable or parameter declaration:
        #   `type /* optional whitespace */ var_name /* optional whitespace */;`
        #   `type /* optional whitespace */ var_name /* optional whitespace */, var_name2`
        #   `(type /* optional whitespace */ var_name /* optional whitespace */)`
        # Note: Only the token for type is produced here.
        rule %r{
                (^#{id})
                (?=
                  (#{ws})+
                  (#{id})
                )
              }mx do |m|
          token Keyword::Type, m[1]
        end
      end

      state :infos do
        rule %r/(args|res|upd|label|rep|srt|arity|fun_type|arg_space|updfr_space)(:)/ do |m|
          token Name::Property, m[1]
          token Punctuation, m[2]
        end

        rule %r/(info_tbls|stack_info)(:)/ do |m|
          token Name::Entity, m[1]
          token Punctuation, m[2]
        end
      end

      state :names do
        rule %r/(Sp|SpLim|Hp|HpLim|HpAlloc|BaseReg|CurrentNursery|CurrentTSO|R\d{1,2}|gcptr)(?!#{id})/, Name::Variable::Global
        rule %r/CLOSURE/, Keyword::Type
        rule %r/True|False/, Name::Builtin
        rule %r/[A-Z]#{id}(?=\.)/, Name::Namespace
        rule %r/#{id}/, Name::Label
      end
    end
  end
end
