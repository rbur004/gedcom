#!/usr/bin/env ruby

#RubyVersion provides checking for the running Ruby interpreter version
#Superceded by the VersionCheck gem

class RubyVersion
  #self.have_version tests that the versien of RUBY is the one we want.
  def self.have_version?(major, minor, update = nil, build = nil)
    v = RUBY_VERSION.split('.')
    if major == v[0].to_i && minor == v[1].to_i
      return false if update != nil && update != v[2].to_i
      return false if build != nil && build !=  RUBY_PATCHLEVEL.to_i
      return true
    else
      return false
    end
  end
  
  #self.have_at_least_version tests that the versien of RUBY is newer than the one we want.
  def self.have_at_least_version?(major, minor, update = nil, build = nil)
    v = RUBY_VERSION.split('.')
    if major == v[0].to_i #Could true
      if minor == v[1].to_i #Could be true
        if update != nil #Being asked to test update level
          if update == v[2].to_i #Could be true
            if build != nil #Being asked to test the build version
              return build <= RUBY_PATCHLEVEL.to_i #have at least the required patch level.
            end
            return true #update was equal
          end
          return update < v[2].to_i #current version is newer
        end
        return true #major and minor was equal.
      end
      return minor < v[1].to_i #true if current version is newer
    end
    return major < v[0].to_i #true, if current version is newer
  end
  
  def self.to_s
    "RUBY #{RUBY_VERSION} Build #{RUBY_PATCHLEVEL}"
  end
end

#puts RubyVersion.to_s
#puts RubyVersion.have_version?(1,9)
