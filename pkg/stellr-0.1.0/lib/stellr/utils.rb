require 'stellr/utils/shutdown'
require 'stellr/utils/observable'

class String

  # Constantize tries to find a declared constant with the name specified
  # in the string. It raises a NameError when the name is not in CamelCase
  # or is not initialized.
  #
  # Examples
  #   "Module".constantize #=> Module
  #   "Class".constantize #=> Class
  #
  # Blatantly stolen from rails' activesupport
  def constantize
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self
      raise NameError, "#{self.inspect} is not a valid constant name!"
    end
    classname = $1
    classname.untaint
    Object.module_eval("::#{classname}", __FILE__, __LINE__)
  end

end
