class ZLua < Formula
  desc "New cd command that helps you navigate faster by learning your habits"
  homepage "https://github.com/skywind3000/z.lua"
  url "https://github.com/skywind3000/z.lua/archive/refs/tags/1.8.19.tar.gz"
  sha256 "ef09629900421ff894df7e1cb16134e594e8af20364c900804c4a939fae48f4c"
  license "MIT"
  head "https://github.com/skywind3000/z.lua.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, all: "6191e86bba986a68933b07d9ceb1ad4e9c7b050441d5ccaebecfc06fe9e78764"
  end

  depends_on "lua"

  def install
    pkgshare.install "z.lua", "z.lua.plugin.zsh", "init.fish"
    doc.install "README.md", "LICENSE"
  end

  def caveats
    <<~EOS
      Zsh users: add line below to your ~/.zshrc
        eval "$(lua $(brew --prefix z.lua)/share/z.lua/z.lua --init zsh)"

      Bash users: add line below to your ~/.bashrc
        eval "$(lua $(brew --prefix z.lua)/share/z.lua/z.lua --init bash)"
    EOS
  end

  test do
    system "lua", "#{opt_pkgshare}/z.lua", "."
  end
end
