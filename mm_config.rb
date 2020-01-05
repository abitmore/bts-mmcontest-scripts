#!/usr/bin/env ruby

$snapshot_root_path = "/home/www/html/snapshots"

$proposer = "abit"

$start_date = Date.parse("2020-01-03")
$end_date = Date.parse("2020-01-03")

$min_order_bts_amount = 100*100000 # 100 BTS
$group_bts_amount_cap = 1000*1000*100000 # 1M BTS

$coins = [ :BTC, :USDT, :ETH, :EOS ]
$assets = {
#  testnet
=begin
  "1.3.1515" => { :coin => :BTC,  :name => "CONTEST.BTC" },
  "1.3.1516" => { :coin => :USDT, :name => "CONTEST.USD1" },
  "1.3.1517" => { :coin => :USDT, :name => "CONTEST.USD2" },
=end
#  mainnet
#  "1.3.861"  => { :coin => :BTC, :name => "OPEN.BTC"},
#  "1.3.1570" => { :coin => :BTC, :name => "BRIDGE.BTC"},
  "1.3.2241" => { :coin => :BTC, :name => "GDEX.BTC"},
  "1.3.3926" => { :coin => :BTC, :name => "RUDEX.BTC"},
  "1.3.4157" => { :coin => :BTC, :name => "XBTSX.BTC"},
  "1.3.4198" => { :coin => :BTC, :name => "SPARKDEX.BTC"},
#  "1.3.1042" => { :coin => :USDT, :name => "OPEN.USDT"},
#  "1.3.5144" => { :coin => :USDT, :name => "BRIDGE.USDT"},
  "1.3.5286" => { :coin => :USDT, :name => "GDEX.USDT"},
  "1.3.5542" => { :coin => :USDT, :name => "RUDEX.USDT"},
  "1.3.5589" => { :coin => :USDT, :name => "XBTSX.USDT"},
#
  "1.3.2598" => { :coin => :ETH, :name => "GDEX.ETH"},
  "1.3.3715" => { :coin => :ETH, :name => "RUDEX.ETH"},
  "1.3.4199" => { :coin => :ETH, :name => "SPARKDEX.ETH"},
  "1.3.4760" => { :coin => :ETH, :name => "XBTSX.ETH"},
#
  "1.3.4106" => { :coin => :EOS, :name => "RUDEX.EOS"},
}

#  "id": "1.3.861", "symbol": "OPEN.BTC",
#  "id": "1.3.1570", "symbol": "BRIDGE.BTC", --gateway closing, removed
#  "id": "1.3.2241", "symbol": "GDEX.BTC",
#  "id": "1.3.3926", "symbol": "RUDEX.BTC",
#  "id": "1.3.4157", "symbol": "XBTSX.BTC",
#  "id": "1.3.4198", "symbol": "SPARKDEX.BTC",
#
#  "id": "1.3.1042", "symbol": "OPEN.USDT",
#  "id": "1.3.5144", "symbol": "BRIDGE.USDT", --gateway closing, removed
#  "id": "1.3.5286", "symbol": "GDEX.USDT",
#  "id": "1.3.5542", "symbol": "RUDEX.USDT",
#  "id": "1.3.5589", "symbol": "XBTSX.USDT",
#
#  "id": "1.3.850", "symbol": "OPEN.ETH",
#  "id": "1.3.2598", "symbol": "GDEX.ETH",
#  "id": "1.3.3715", "symbol": "RUDEX.ETH",
#  "id": "1.3.4199", "symbol": "SPARKDEX.ETH",
#  "id": "1.3.4760", "symbol": "XBTSX.ETH",
#
#  "id": "1.3.1999", "symbol": "OPEN.EOS",
#  "id": "1.3.2635", "symbol": "GDEX.EOS",
#  "id": "1.3.4106", "symbol": "RUDEX.EOS",


$daily_rewards = {
  :BTC => { :sells => 4500*100000, :buys => 10500*100000 },
  :USDT => { :sells => 4500*100000, :buys => 10500*100000 },
  :ETH => { :sells => 4500*100000, :buys => 10500*100000 },
  :EOS => { :sells => 4500*100000, :buys => 10500*100000 },
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

