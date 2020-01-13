#!/usr/bin/env ruby

$snapshot_root_path = "/home/www/html/snapshots"

$proposer = "abit"

$start_date = Date.parse("2020-01-12")
$end_date = Date.parse("2020-01-12")

$min_order_bts_amount = 100*100000 # 100 BTS
$group_bts_amount_cap = 1000*1000*100000 # 1M BTS

$coins = [ :BTC, :USDT, :ETH, :EOS ]
$assets = {
  "1.3.2241" => { :coin => :BTC, :name => "GDEX.BTC", :precision => 8 },
  "1.3.3926" => { :coin => :BTC, :name => "RUDEX.BTC", :precision => 8 },
  "1.3.4157" => { :coin => :BTC, :name => "XBTSX.BTC", :precision => 8 },
  "1.3.4198" => { :coin => :BTC, :name => "SPARKDEX.BTC", :precision => 7 },
#
  "1.3.5286" => { :coin => :USDT, :name => "GDEX.USDT", :precision => 7 },
  "1.3.5542" => { :coin => :USDT, :name => "RUDEX.USDT", :precision => 6 },
  "1.3.5589" => { :coin => :USDT, :name => "XBTSX.USDT", :precision => 6 },
#
  "1.3.2598" => { :coin => :ETH, :name => "GDEX.ETH", :precision => 6 },
  "1.3.3715" => { :coin => :ETH, :name => "RUDEX.ETH", :precision => 7 },
  "1.3.4199" => { :coin => :ETH, :name => "SPARKDEX.ETH", :precision => 6 },
  "1.3.4760" => { :coin => :ETH, :name => "XBTSX.ETH", :precision => 7 },
#
  "1.3.2635" => { :coin => :EOS, :name => "GDEX.EOS", :precision => 6 },
  "1.3.4106" => { :coin => :EOS, :name => "RUDEX.EOS", :precision => 4 },
}

$bitassets = {
  "1.3.113"  => { :name => "CNY",   :precision => 4 },
  "1.3.121"  => { :name => "USD",   :precision => 4 },
  "1.3.120"  => { :name => "EUR",   :precision => 4 },
  "1.3.1325" => { :name => "RUBLE", :precision => 5 },
}

$bts_market_daily_rewards = {
  :BTC  => { :sells => 3000*100000, :buys => 7000*100000 },
  :USDT => { :sells => 3000*100000, :buys => 7000*100000 },
  :ETH  => { :sells => 3000*100000, :buys => 7000*100000 },
  :EOS  => { :sells => 3000*100000, :buys => 7000*100000 },
}

$base_precision = 8
$base_sat = 10**$base_precision

$bitasset_market_reward_params = {
  :BTC  => { :sells => 2500*100000, :buys => 2500*100000, :min_order_size => $base_sat     / 1000, :target_depth_per_group => $base_sat * 4 },
  :ETH  => { :sells => 2500*100000, :buys => 2500*100000, :min_order_size => $base_sat * 5 / 100,  :target_depth_per_group => $base_sat * 200 },
  :EOS  => { :sells => 2500*100000, :buys => 2500*100000, :min_order_size => $base_sat * 2,        :target_depth_per_group => $base_sat * 10000 },
  :USDT => { :sells => 2500*100000, :buys => 2500*100000, :min_order_size => $base_sat * 10,       :target_depth_per_group => $base_sat * 50000 },
}

$group_reward_percent = [ 0, Rational(53,100), Rational(25,100), Rational(12,100), Rational(6,100), Rational(3,100), Rational(1,100),  0 ]
$group_bounds         = [ 0, Rational(1,100),  Rational(2,100),  Rational(3,100),  Rational(5,100), Rational(7,100), Rational(10,100), 1 ]

def distance_to_group( distance )
  return 1 if distance <= $group_bounds[1]
  return 2 if distance <= $group_bounds[2]
  return 3 if distance <= $group_bounds[3]
  return 4 if distance <= $group_bounds[4]
  return 5 if distance <= $group_bounds[5]
  return 6 if distance <= $group_bounds[6]
  return 7
end

if __FILE__ == $0

end
__END__

