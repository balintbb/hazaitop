# -*- encoding : utf-8 -*-
class Guest < Hobo::Guest

  def administrator?
    false
  end

  def editor?
    false
  end

  def supervisor?
    false
  end

end

