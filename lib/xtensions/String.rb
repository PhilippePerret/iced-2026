=begin
  String extension for CLIR
=end

class String

  CHIFFRE_HAUT = {
    0 => '⁰',
    1 => '¹',
    2 => '²',
    3 => '³',
    4 => '⁴',
    5 => '⁵',
    6 => '⁶',
    7 => '⁷',
    8 => '⁸',
    9 => '⁹'
  }
  CHIFFRE_BAS = {
    0 => '₀',
    1 => '₁',
    2 => '₂',
    3 => '₃',
    4 => '₄',
    5 => '₅',
    6 => '₆',
    7 => '₇',
    8 => '₈',
    9 => '₉'
  }

  DATA_NORMALIZE = {
    :from => "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
    :to   => "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
  }

  def self.columnize(lines, delimitor = ',', gutter = '    ')
    # lines = lines.join("\n") if lines.is_a?(Array)
    lines = lines.split("\n") if lines.is_a?(String)
    # 
    # Nombre de colonnes
    # 
    nombre_colonnes = 0
    colonnes_widths = []
    lines = lines.map do |line|
      line.strip.split(delimitor).map {|e| e.strip}
    end.each do |line|
      nb = line.count # nombre de colonnes
      nombre_colonnes = nb if nb > nombre_colonnes
    end
    # 
    # On met le même nombre de colonnes à toutes les lignes
    # 
    lines.map do |line|
      while line.count < nombre_colonnes
        line << ''
      end
      line
    end.each do |line|
      line.each_with_index do |str, col_idx|
        colonnes_widths[col_idx] = 0 if colonnes_widths[col_idx].nil?
        colonnes_widths[col_idx] = str.length if str.length > colonnes_widths[col_idx]
      end
    end.each do |line|
      # 
      # Mettre toutes les colonnes à la même taille
      # 
      line.each_with_index do |str, col_idx|
        line[col_idx] = str.ljust(colonnes_widths[col_idx])
      end
    end

    lines.map do |line|
      line.join(gutter)
    end.join("\n").strip
    
  end

  # --- Predicate Methods ---

  # @return TRUE is +str+ is a number (integer or float) in a string.
  def numeric?
    self.match?(/^[0-9.]+$/)
  end

  # @return TRUE if +ary+, as a String or an Array, includes
  # self. If it's an Hash, has key self.
  def in?(ary)
    case ary
    when Array
      ary.include?(self)
    when String
      ary.match?(self)
    when Hash
      ary.key?(self)
    else
      raise "in? waits for a String, an Hash or a Array. Given: #{ary.class}."
    end
  end

  # --- Helpers Methods ---

  def nil_if_empty
    if self.gsub(/[\n\r\t  ]/, '') === ""
      return nil
    else
      return self
    end
  end

  ##
  # @return self with +len+ length. Cut it if necessary.
  # @note
  #   Up to 10, cut at the end with '…' separator
  #   Up to 15, cut at the middle and if diff < 5, the separator is '…'
  # @example
  #   "Sentence".max(5) # => "Sent…"
  #   "Long sentence".max(10) # => "Long…tence"
  #   "Very long and long sentence".max(16)
  #   # => "Very lo[…]ntence"
  # 
  # @param [Integer] len Lenght required (> 1)
  # 
  def max(len)
    len.is_a?(Integer) || raise(ArgumentError.new("Argument should be a Integer"))
    len > 1 || raise(ArgumentError.new("Minimum length should be 2. You give #{len}."))
    return "#{self}"            if self.length <= len
    return self[0...len-1]+'…'  if len <= 10
    cur_len = self.length
    diff    = cur_len - len

    sep, moitie = 
      if len > 15 && diff > 4
        ['[…]', len / 2 - 2]
      else
        ['…', len / 2]
      end

    midav = self[0..moitie-1] + sep
    reste = len - midav.length
    midap = self[-reste..-1]

    return midav + midap
  end

  def max!(len)
    self.replace(self.max(len))
    return true
  end


  # As ljust (which align to the left) ans rjust (which align to the
  # right), cjust align to the center depending length
  # @example
  #   "good".cjust(10) # => "   good   "
  #   "good".cjust(10, '+') # => "+++good+++"
  def cjust(length, fill_with = ' ')
    if self.length == length
      return self
    elsif self.length > length 
      return self[0...length]
    else
      nombre_moitie = (length - self.length) / 2
      ret = (fill_with * nombre_moitie) + self + (fill_with * nombre_moitie)
      ret = ret + fill_with if ret.length < length
      return ret
    end
  end

  # Si le texte est :
  # 
  #       Mon titre
  # 
  # … cette méthode retourne :
  # 
  #       Mon titre
  #       ---------
  # 
  # 
  def as_title(sous = '=', indent = 2)
    len = self.length
    ind = ' ' * indent
    del = ind + sous * (len + 2)
    "\n#{del}\n#{ind} #{self.upcase}\n#{del}"
  end


  def strike
    "\033[9m#{self}\033[0m"
  end
  def underline
    "\033[4m#{self}\033[0m"
  end
  def italic
    "\033[3m#{self}\033[0m"
  end


  def blanc
    "\033[0;38m#{self}\033[0m"
  end
  alias :white :blanc
  def blanc_
    "\033[0;38m#{self}"
  end

  def blanc_clair
    "\033[0;37m#{self}\033[0m"
  end
  def blanc_clair_
    "\033[0;37m#{self}"
  end
  
  def bleu
    "\033[0;96m#{self}\033[0m"
  end
  alias :blue :bleu
  
  def bleu_
    "\033[0;96m#{self}"
  end

  def bleu_clair
    "\033[0;36m#{self}\033[0m"
  end
  def bleu_clair_
    "\033[0;36m#{self}"
  end


  def fond_bleu
    "\033[0;44m#{self}\033[0m"
  end

  def fond_bleu_clair
    "\033[0;46m#{self}\033[0m"
  end

  def vert
    "\033[0;92m#{self}\033[0m"
  end
  alias :green :vert
  def vert_
    "\033[0;92m#{self}"
  end

  def vert_clair
    "\033[0;32m#{self}\033[0m"
  end
  alias :ligth_green :vert_clair
  def vert_clair_
    "\033[0;32m#{self}"
  end

  def fond_vert
    "\033[0;42m#{self}\033[0m"
  end

  def rouge
    "\033[0;91m#{self}\033[0m"
  end
  alias :red :rouge
  def rouge_
    "\033[0;91m#{self}"
  end

  def gris
    "\033[0;90m#{self}\033[0m"
  end
  alias :grey :gris
  def gris_
    "\033[0;90m#{self}"
  end

  def orange
    "\033[38;5;214m#{self}\033[0m"
  end
  def orange_
    "\033[38;5;214m#{self}"
  end
 
  def jaune
    "\033[0;93m#{self}\033[0m"
  end
  alias :yellow :jaune
  def jaune_
    "\033[0;93m#{self}"
  end

  def jaune_dark
    "\033[0;33m#{self}\033[0m"
  end

  def mauve
    "\033[1;94m#{self}\033[0m"
  end
  alias :purple :mauve
  def mauve_
    "\033[1;94m#{self}"
  end


  # --- Transform Methods ---

  def camelize
    str = "#{self}"
    str[0] = str[0].upcase
    str.split(' ').map do |seg|
      seg.gsub(/(?:_+([a-z]))/i){$1.upcase}
    end.join(' ')
  end

  def decamelize
    str = self
    str[0] = str[0].downcase
    str.split(' ').map do |seg|
      seg.gsub(/([A-Z])/){ "_#{$1.downcase}"}
    end.join(' ')
  end

  def titleize
    str = self
    str.split(' ').map { |n| n[0].upcase + n[1..-1].downcase }.join(' ')
  end

  def patronize
    str = self
    str.split(/( |\-)/).map do |n|
      n = n.downcase
      if n == 'de' 
        'de'
      else
        n.capitalize 
      end
    end.join('')
  end

  def normalize
    self
      .force_encoding('utf-8')
      .gsub(/[œŒæÆ]/,{'œ'=>'oe', 'Œ' => 'Oe', 'æ'=> 'ae', 'Æ' => 'Ae'})
      .tr(DATA_NORMALIZE[:from], DATA_NORMALIZE[:to])
  end
  alias :normalized :normalize

end #/class String
