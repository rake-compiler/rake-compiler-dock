# This file is part of Libusb for Ruby.
#
# Libusb for Ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Libusb for Ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Libusb for Ruby.  If not, see <http://www.gnu.org/licenses/>.

require "bundler/gem_helper"

module RakeCompilerDock
  class GemHelper < Bundler::GemHelper
    def install
      super

      task "release:guard_clean" => ["release:update_history"]

      task "release:update_history" do
        update_history
      end
    end

    def hfile
      "History.md"
    end

    def headline
      '([^\w]*)(\d+\.\d+\.\d+)([^\w]+)([2Y][0Y][0-9Y][0-9Y]-[0-1M][0-9M]-[0-3D][0-9D])([^\w]*|$)'
    end

    def reldate
      Time.now.strftime("%Y-%m-%d")
    end

    def version_tag
      "#{version}"
    end

    def update_history
      hin = File.read(hfile)
      hout = hin.sub(/#{headline}/) do
        raise "#{hfile} isn't up-to-date for version #{version}" unless $2==version.to_s
        $1 + $2 + $3 + reldate + $5
      end
      if hout != hin
        Bundler.ui.confirm "Updating #{hfile} for release."
        File.write(hfile, hout)
        Rake::FileUtilsExt.sh "git", "commit", hfile, "-m", "Update release date in #{hfile}"
      end
    end

    def tag_version
      Bundler.ui.confirm "Tag release with annotation:"
      m = File.read(hfile).match(/(?<annotation>#{headline}.*?)#{headline}/m) || raise("Unable to find release notes in #{hfile}")
      Bundler.ui.info(m[:annotation].gsub(/^/, "    "))
      IO.popen(["git", "tag", "--file=-", version_tag], "w") do |fd|
        fd.write m[:annotation]
      end
      yield if block_given?
    rescue
      Bundler.ui.error "Untagging #{version_tag} due to error."
      sh_with_code "git tag -d #{version_tag}"
      raise
    end
  end
end
