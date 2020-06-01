# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# uses the rust lexer as a starting point

module Rouge
  module Lexers
    class Zig < RegexLexer
      tag 'zig'
      aliases 'zir'
      filenames '*.zig'
      mimetypes 'text/x-zig'

      title 'Zig'
      desc 'The Zig programming language'

      def self.keywords 
        @keywords ||= %w(
          align linksection threadlocal struct enum union error break return
          anyframe fn c_longlong c_ulonglong c_longdouble c_void comptime_float
          c_short c_ushort c_int c_uint c_long c_ulong continue asm defer
          errdefer const var extern packed export pub if else switch and or
          orelse while for bool unreachable try catch async suspend nosuspend
          await resume undefined usingnamespace test void noreturn type
          anyerror usize noalias inline noinline comptime callconv volatile
          allowzero
        )
      end

      def self.builtins
        @builtins ||= %w(
          @addWithOverflow @as @atomicLoad @atomicStore @bitCast @breakpoint
          @alignCast @alignOf @cDefine @cImport @cInclude @bitOffsetOf
          @atomicRmw @bytesToSlice @byteOffsetOf @OpaqueType @panic @ptrCast
          @bitReverse @Vector @sin @cUndef @canImplicitCast @clz @cmpxchgWeak
          @cmpxchgStrong @compileError @compileLog @ctz @popCount @divExact
          @divFloor @cos @divTrunc @embedFile @export @tagName @TagType
          @errorName @call @errorReturnTrace @fence @fieldParentPtr @field
          @unionInit @errorToInt @intToEnum @enumToInt @setAlignStack @frame
          @Frame @exp @exp2 @log @log2 @log10 @fabs @floor @ceil @trunc @round
          @floatCast @intToFloat @floatToInt @boolToInt @errSetCast @intToError
          @frameAddress @import @newStackCall @asyncCall @intToPtr @intCast
          @frameSize @memcpy @memset @mod @mulWithOverflow @splat @ptrToInt
          @rem @returnAddress @setCold @Type @shuffle @setGlobalLinkage
          @setGlobalSection @shlExact @This @hasDecl @hasField
          @setRuntimeSafety @setEvalBranchQuota @setFloatMode @shlWithOverflow
          @shrExact @sizeOf @bitSizeOf @sqrt @byteSwap @subWithOverflow
          @sliceToBytes comptime_int @truncate @typeInfo @typeName @TypeOf
        )
      end

      id = /[a-z_]\w*/i
      hex = /[0-9a-f]/i
      escapes = %r(
      \\ ([nrt'"\\0] | x#{hex}{2} | u#{hex}{4} | U#{hex}{8})
      )x

      state :bol do
        mixin :whitespace
        rule %r/#\s[^\n]*/, Comment::Special
        rule(//) { pop! }
      end

      state :attribute do
        mixin :whitespace
        mixin :has_literals
        rule %r/[(,)=:]/, Name::Decorator
        rule %r/\]/, Name::Decorator, :pop!
        rule id, Name::Decorator
      end

      state :whitespace do
        rule %r/\s+/, Text
        rule %r(//[^\n]*), Comment
      end

      state :root do
        rule %r/\n/, Text, :bol
        mixin :whitespace
        rule %r/\b(?:#{Zig.keywords.join('|')})\b/, Keyword
          rule %r/\b(?:(i|u)[0-9]+)\b/, Keyword
        rule %r/\b(?:f(16|32|64|128))\b/, Keyword
        rule %r/\b(?:(isize|usize))\b/, Keyword
        mixin :has_literals

        rule %r/[()\[\]{}|,:;]/, Punctuation
        rule %r/[*\/!@~&+%^<>=\?-]|\.{1,3}/, Operator

        rule %r/([.]\s*)?#{id}(?=\s*[(])/m, Name::Function
        rule %r/[.]\s*#{id}/, Name::Property
        rule %r/'#{id}/, Name::Variable
        rule %r/#{id}/ do |m|
          name = m[0]
          if self.class.builtins.include? name
            token Name::Builtin
          else
            token Name
          end
        end
      end

      state :has_literals do
        rule %r/\b(?:true|false|null)\b/, Keyword::Constant
        rule %r(
        ' (?: #{escapes} | [^\\] ) '
        )x, Str::Char

        rule %r/"/, Str, :string
        rule %r/r(#*)".*?"\1/m, Str

        dot = /[.][0-9_]+/
        exp = /e[-+]?[0-9_]+/

        rule %r(
          [0-9]+
          (#{dot}  #{exp}?
          |#{dot}? #{exp} 
          )
        )x, Num::Float

        rule %r(
        ( 0b[10_]+
         | 0x[0-9a-fA-F_]+
         | [0-9_]+
        )
        )x, Num::Integer
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule escapes, Str::Escape
        rule %r/[^"\\]+/m, Str
      end
    end
  end
end
