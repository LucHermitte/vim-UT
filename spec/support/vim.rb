# File inspired by Andrew Radev's splitjoin plugin

module Support
  module Vim
    def clear_buffer
      vim.normal('ggdG')
    end

    def set_file_contents(string)
      write_file(filename, string)
      vim.edit!(filename)
    end

    def set_buffer_contents(string)
      string = normalize_string_indent(string)
      string = string.split(/\r?\n/)
      vim.command(%Q{call setline(1, #{string})})
    end

    def assert_file_contents(string)
      string = normalize_string_indent(string)
      expect(IO.read(filename).strip).to eq(string)
    end

    def assert_buffer_contents(string)
      string = normalize_string_indent(string)
      expect(vim.echo('join(getline(1, "$"), "\\n")')).to eq(string)
      # expect(vim.echo('getline(1, "$")').strip).to eq(string)
    end

    def assert_line_contents(string)
      string = normalize_string_indent(string)
      expect(vim.echo('getline(".")')).to eq(string)
      # expect(vim.echo('getline(1, "$")').strip).to eq(string)
    end
  end
end

# vim:set sw=2:
