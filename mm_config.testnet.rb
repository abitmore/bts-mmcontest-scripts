#!/usr/bin/env ruby

$snapshot_root_path = "snapshots"

$start_date = Date.parse("2019-10-20")
$end_date = Date.parse("2019-10-20")

$min_order_bts_amount = 100*100000 # 100 BTS
$group_bts_amount_cap = 1000*1000*100000 # 1M BTS

$coins = [ :BTC, :USDT ]
$assets = {
#  testnet
  "1.3.1515" => { :coin => :BTC,  :name => "CONTEST.BTC" },
  "1.3.1516" => { :coin => :USDT, :name => "CONTEST.USD1" },
  "1.3.1517" => { :coin => :USDT, :name => "CONTEST.USD2" },
#  mainnet
=begin
  "1.3.861"  => { :coin => :BTC, :name => "OPEN.BTC"},
  "1.3.1570" => { :coin => :BTC, :name => "BRIDGE.BTC"},
  "1.3.2241" => { :coin => :BTC, :name => "GDEX.BTC"},
  "1.3.3926" => { :coin => :BTC, :name => "RUDEX.BTC"},
  "1.3.4157" => { :coin => :BTC, :name => "XBTSX.BTC"},
  "1.3.4198" => { :coin => :BTC, :name => "SPARKDEX.BTC"},
  "1.3.1042" => { :coin => :USDT, :name => "OPEN.USDT"},
  "1.3.5144" => { :coin => :USDT, :name => "BRIDGE.USDT"},
  "1.3.5286" => { :coin => :USDT, :name => "GDEX.USDT"},
=end
}


$daily_rewards = {
  :BTC => { :sells => 300*100000, :buys => 29700*100000 },
  :USDT => { :sells => 300*100000, :buys => 29700*100000 },
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

