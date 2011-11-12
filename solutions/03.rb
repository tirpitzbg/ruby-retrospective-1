require 'bigdecimal'
require 'bigdecimal/util'

class Product
  attr_accessor :name, :price, :promo
  
  def initialize(name, price, *promo)
    @name = name
    @price = price.to_d
    @promo = (promo == [] ? nil : promo[0])
  end

end

class Coupon
  attr_accessor :name, :type
  
  def initialize(name, type)
    @name = name
    @type = type
  end
  
end

class Pcm
  
  def self.ending(num)
    case num
      when 1 then "1st"
      when 2 then "2nd"
      when 3 then "3rd"
      else num.to_s + "th"
    end
  end
  
  def self.kv(k, v)
    start = "| " + k
    start + " " * ((v > 9 ? 46 : 47) - start.length) + v.to_s + " |"
  end
  
  def self.ins(promo, save)
    if promo == []
      return ""
    end
    k, v = promo.keys[0], promo.values[0]
    if v.kind_of? Hash
      v1 = v.keys[0]
      v2 = v[v1]
    end
    u, dsc = "% off of every after the ", "% off for every "
  
    case k
      when :get_one_free then e = "|   (buy " + (v - 1).to_s + ", get 1 free)"
      when :package then e = "|   (get " + v2.to_s + dsc + v1.to_s + ")"
      when :threshold then e = "|   (" + v2.to_s + u + self.ending(v1) + ")"
    end
    e + " " * (49 - e.length) + "|" + sprintf("%9.2f", -save) + " |\n"
  end
  
  def self.invoice_sc(name, coupon, save)
    k = coupon.keys[0]
    v = coupon[k]
    start = "| Coupon " + name + " - " + v.to_s
    if k == :percent
      start << "%"
    end
    start << " off"
    start + " " * (49 - start.length) + "|" + sprintf("%9.2f", -save) + " |\n"
  end

  def self.calc_promo(k, v, cnt, perc, v1, v2, price)
    case k
      when :get_one_free then price * (cnt - cnt / v)				 
      when :package then price * ((cnt - cnt % v1) * perc + (cnt % v1))
      when :threshold then price * ([v1, cnt].min + perc * [(cnt - v1), 0].max)
    end
  end
  
  def self.invoice_end(q, total)
    ret = q + "| " + sprintf("%s %41s", "TOTAL", "") + "|"
    ret << sprintf("%9.2f", total) + " |"+ "\n" + q
  end
  
  def self.get_p(item, pr)
    pr.select {|p| p.name == item} [0].price
  end
  
  def self.gp(item, pr)
    pr.select {|p| p.name == item} [0].promo
  end
  
end

class Cart
  attr_accessor :contents, :pr, :using, :coupons
  
  def initialize(pr, coupons)
    @contents = {}
    @pr = pr
    @coupons = coupons
	@q = "+------------------------------------------------+----------+\n"
  end
  
  def add(name, *count_opt)
    count = (count_opt == [] ? 1 : count_opt[0])
    if @pr.collect {|p| p.name == name}.count(true) == 0 || count < 1
      raise "Invalid parameters passed."
    end
    if !contents.has_key?(name)
      contents[name] = 0
    end
    contents[name] += count
	(contents[name] > 99) ? (raise "Invalid parameters passed.") : 0
  end
  
  def use(coupon)
    @using = coupon
  end
 
  def get_ptc(item, count)
    product = @pr.select {|p| p.name == item} [0]
    if product.promo == []
      return product.price * count
    end
    k, v = product.promo.keys[0], product.promo.values[0]
    if v.kind_of? Hash
	  v1, v2, perc = v.keys[0], v.values[0], (((100.0 - v.values[0]) / 100.0).to_d)
    end
    Pcm.calc_promo(k, v, count, perc, v1, v2, product.price)
  end
  
  def get_cd(sum)
    if @using == nil
	  return 0
	end
    k = @coupons[@using].keys[0]
    v = BigDecimal(@coupons[@using][k].to_s)
    case k
      when :percent then sum - (sum * (100 - v) / 100)
      when :amount then [v, sum].min
    end
  end
  
  def tot_wc
    sum = BigDecimal('0')
    @contents.each do |k, v|
      sum += get_ptc(k, v)
    end
    sum
  end
  
  def total
    tot_wc - get_cd(tot_wc)
  end
  
  
  
  def invoice
    result = @q + "| Name" + " " * 39 + "qty |    price |\n" + @q
    @contents.each do |k, v|
      result << Pcm.kv(k, v) + sprintf("%9.2f", Pcm.get_p(k, pr) * v) + " |\n"
      result << Pcm.ins(Pcm.gp(k, @pr), Pcm.get_p(k, pr) * v - get_ptc(k, v))
    end
    if @using != nil
      result << Pcm.invoice_sc(@using, @coupons[@using], get_cd(tot_wc))
    end
	result << Pcm.invoice_end(@q, total)
  end
  
end

class Inventory
  attr_accessor :pr, :coupons
  
  def initialize
    @pr = []
    @coupons = {}
  end
  
  def check_register_data(name, price)
    if (!name.kind_of? String) or (!price.kind_of? String)
      raise "Invalid parameters passed."
    end
    if name.length > 40 or price.to_d < 0.01 or price.to_d > 999.99
      raise "Invalid parameters passed."
    end
    if @pr.collect {|p| p.name == name}.count(true) > 0
      raise "Invalid parameters passed."
    end
  end
  
  def register(name, price, *promo)
    check_register_data(name, price)
    @pr << Product.new(name, price, (promo == [] ? [] : promo[0]))
  end
  
  def register_coupon(name, type)
    @coupons[name] = type
  end
  
  def new_cart
    Cart.new(@pr, @coupons)
  end
  
 end