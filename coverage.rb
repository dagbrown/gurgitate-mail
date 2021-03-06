# -*- encoding : utf-8 -*-
SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

module COVERAGE__
    INCLUDE_FILES=/gurgitate-mail.rb/
    COVER = {}
    def self.trace_func(event, file, line, id, binding, klass)
        case event
        when 'c-call', 'c-return', 'class'
            return
        end
        COVER[file] ||= []
        COVER[file][line] ||= 0
        COVER[file][line] += 1
    end

    END {
        set_trace_func(nil)
        COVER.each do |file, lines|
            next unless file =~ INCLUDE_FILES
            if SCRIPT_LINES__.has_key?(file)
                printf("--- %s\n", file)
                lines = SCRIPT_LINES__[file]
                covers = COVER[file]
                0.upto(lines.size - 1) do |c|
                    line = lines[c].chomp
                    marked = false
                    if covers[c + 1]
                        marked = true
                    elsif /^\s*(?:begin\s*(?:#.*)?|ensure\s*(?:#.*)?|else\s*(?:#.*)?)$/ =~ line and covers[c + 1 + 1]
                        covers[c + 1] = covers[c + 1 + 1]
                        marked = true
                    elsif /^\s*(?:end|\})\s*$/ =~ line && covers[c + 1 - 1]
                        covers[c + 1] = covers[c + 1 - 1]
                        marked = true
                    end
                    if marked
                        printf("+ %s\n", line)
                    else
                        printf("  %s\n", line)
                    end
                end
            end
        end
    }

    set_trace_func(COVERAGE__.method(:trace_func).to_proc)
end

