#!/usr/bin/env ruby

require 'time'
require 'json'
require 'bigdecimal'

require_relative 'mm_config'

def process_snapshots( snapshot_path, score_path, date )

  #puts snapshot_path, score_path, date
  puts date

  # for BTS markets
  daily_trader_scores = {}
  daily_trader_rewards = {}
  daily_coin_group_data = {}
  $coins.each { |coin| daily_trader_scores[coin] = { :sells => {}, :buys => {} } }
  $coins.each { |coin| daily_trader_rewards[coin] = { :sells => {}, :buys => {} } }
  $coins.each { |coin| daily_coin_group_data[coin] = { :sells => {}, :buys => {} } }

  # for bitasset markets
  daily_trader_scores2 = {}
  daily_trader_rewards2 = {}
  daily_coin_group_data2 = {}
  $coins.each { |coin| daily_trader_scores2[coin] = { :sells => {}, :buys => {} } }
  $coins.each { |coin| daily_trader_rewards2[coin] = { :sells => {}, :buys => {} } }
  $coins.each { |coin| daily_coin_group_data2[coin] = { :sells => {}, :buys => {} } }

  blocks = 0
  Dir.foreach(snapshot_path) { |file|
    next if file == '.' or file == '..'
    blocks += 1
    #puts blocks if blocks % 100 == 0
    order_strs = IO.readlines( File.join snapshot_path, file )

    orders = {}    #   BTS / asset
    bitorders = {} # asset / bitasset
    $assets.each { |asset,detail|
       orders[asset] = { :sells => [], :buys => [] }
       bitorders[asset] = {}
       $bitassets.each { |bitasset,bitdetail|
          bitorders[asset][bitasset] = { :sells => [], :buys => [] }
       }
    }

    order_strs.each { |order_str|
      #{"id":"1.7.890509","expiration":"2020-10-14T23:20:23","seller":"1.2.3833","for_sale":1000000000,"sell_price":{"base":{"amount":1000000000,"asset_id":"1.3.1517"},"quote":{"amount":"10000000000","asset_id":"1.3.0"}},"deferred_fee":100,"deferred_paid_fee":{"amount":0,"asset_id":"1.3.0"}}
      order = JSON.parse( order_str );

      asset_for_sale = order["sell_price"]["base"]["asset_id"] # asset for sale
      asset_to_buy = order["sell_price"]["quote"]["asset_id"] # asset to buy

      trader = order["seller"]
      price = Rational( order["sell_price"]["base"]["amount"], order["sell_price"]["quote"]["amount"] )
      for_sale = order["for_sale"].to_i

      if asset_for_sale == "1.3.0" # selling BTS
         asset = asset_to_buy
         next if not $assets.has_key? asset
         bts_amount = for_sale
         next if bts_amount < $min_order_bts_amount
         price = 1 / price
         o = { :trader => trader, :price => price, :bts_amount => bts_amount }
         orders[asset][:sells].push o

      elsif asset_to_buy == "1.3.0" # buying BTS
         asset = asset_for_sale
         next if not $assets.has_key? asset
         bts_amount = (for_sale / price).to_i
         next if bts_amount < $min_order_bts_amount
         o = { :trader => trader, :price => price, :bts_amount => bts_amount }
         orders[asset][:buys].push o

      elsif $bitassets.has_key? asset_to_buy # selling asset
         asset = asset_for_sale
         next if not $assets.has_key? asset
         asset_amount = for_sale * (10 ** ($base_precision - $assets[asset][:precision]))
         next if asset_amount < $bitasset_market_reward_params[$assets[asset][:coin]][:min_order_size]
         price = 1 / price
         o = { :trader => trader, :price => price, :asset_amount => asset_amount }
         bitasset = asset_to_buy
         bitorders[asset][bitasset][:sells].push o

      elsif $bitassets.has_key? asset_for_sale # buying asset
         asset = asset_to_buy
         next if not $assets.has_key? asset
         asset_amount = (for_sale / price).to_i * (10 ** ($base_precision - $assets[asset][:precision]))
         next if asset_amount < $bitasset_market_reward_params[$assets[asset][:coin]][:min_order_size]
         o = { :trader => trader, :price => price, :asset_amount => asset_amount }
         bitasset = asset_for_sale
         bitorders[asset][bitasset][:buys].push o

      else # unknown market
         next
      end

    }
    #puts orders

    # now we have all the valid orders
    # remove the assets that only have orders on one side
    orders.delete_if { |asset,book| book[:buys].empty? or book[:sells].empty? }
    orders.each{ |asset,book|
       hbp = book[:buys][0][:price]
       lap = book[:sells][0][:price]

       book[:sells].each { |order|
          order[:distance] = (order[:price] - hbp) / order[:price]
          order[:group] = distance_to_group( order[:distance] )
          upper_bound = $group_bounds[order[:group]].to_r
          lower_bound = $group_bounds[order[:group]-1].to_r
          order[:weight] = order[:bts_amount] * ( 1 + (upper_bound-order[:distance]) / (upper_bound-lower_bound) )
       }
       book[:sells].delete_if { |order| order[:group] > 6 }
       book[:buys].each { |order|
          order[:distance] = (lap - order[:price]) / lap
          order[:group] = distance_to_group( order[:distance] )
          upper_bound = $group_bounds[order[:group]].to_r
          lower_bound = $group_bounds[order[:group]-1].to_r
          order[:weight] = order[:bts_amount] * ( 1 + (upper_bound-order[:distance]) / (upper_bound-lower_bound) )
       }
       book[:buys].delete_if { |order| order[:group] > 6 }
    }
    orders.delete_if { |asset,book| book[:buys].empty? or book[:sells].empty? }
    #puts orders

    bitorders.each{ |asset,bitbook|
       bitbook.delete_if { |bitasset,book| book[:buys].empty? or book[:sells].empty? }
       bitbook.each{ |bitasset,book|
          hbp = book[:buys][0][:price]
          lap = book[:sells][0][:price]

          book[:sells].each { |order|
             order[:distance] = (order[:price] - hbp) / order[:price]
             order[:group] = distance_to_group( order[:distance] )
             upper_bound = $group_bounds[order[:group]].to_r
             lower_bound = $group_bounds[order[:group]-1].to_r
             order[:weight] = order[:asset_amount] * ( 1 + (upper_bound-order[:distance]) / (upper_bound-lower_bound) )
          }
          book[:sells].delete_if { |order| order[:group] > 6 }
          book[:buys].each { |order|
             order[:distance] = (lap - order[:price]) / lap
             order[:group] = distance_to_group( order[:distance] )
             upper_bound = $group_bounds[order[:group]].to_r
             lower_bound = $group_bounds[order[:group]-1].to_r
             order[:weight] = order[:asset_amount] * ( 1 + (upper_bound-order[:distance]) / (upper_bound-lower_bound) )
          }
          book[:buys].delete_if { |order| order[:group] > 6 }
       }
       bitbook.delete_if { |bitasset,book| book[:buys].empty? or book[:sells].empty? }
    }
    bitorders.delete_if { |asset,bitbook| bitbook.empty? }
    #puts bitorders

    # calculate total score, total weights and etc
    # BTS markets
    coin_group_data = {}
    $coins.each { |coin| coin_group_data[coin] = { :sells => {}, :buys => {} } }
    orders.each{ |asset,book|
      cg = coin_group_data[$assets[asset][:coin]]
      book[:sells].each { |order|
        if not cg[:sells].has_key? order[:group]
          cg[:sells][order[:group]] = { :bts_amount => order[:bts_amount], :weight => order[:weight] }
        else
          cg[:sells][order[:group]][:bts_amount] += order[:bts_amount]
          cg[:sells][order[:group]][:weight] += order[:weight]
        end
      }
      book[:buys].each { |order|
        if not cg[:buys].has_key? order[:group]
          cg[:buys][order[:group]] = { :bts_amount => order[:bts_amount], :weight => order[:weight] }
        else
          cg[:buys][order[:group]][:bts_amount] += order[:bts_amount]
          cg[:buys][order[:group]][:weight] += order[:weight]
        end
      }
    }
    coin_group_data.each { |coin,cg|
      cg[:sells].each{ |group,data|
        data[:score] = BigDecimal.new($group_reward_percent[group] * [1, Rational(data[:bts_amount], $group_bts_amount_cap)].min, 20)
        daily_cg = daily_coin_group_data[coin][:sells]
        if not daily_cg.has_key? group
          daily_cg[group] = { :score => data[:score] }
        else
          daily_cg[group][:score] += data[:score]
        end
      }
      cg[:buys].each{ |group,data|
        data[:score] = BigDecimal.new($group_reward_percent[group] * [1, Rational(data[:bts_amount], $group_bts_amount_cap)].min, 20)
        daily_cg = daily_coin_group_data[coin][:buys]
        if not daily_cg.has_key? group
          daily_cg[group] = { :score => data[:score] }
        else
          daily_cg[group][:score] += data[:score]
        end
      }
    }
    #puts coin_group_data

    # bitasset markets
    coin_group_data2 = {}
    $coins.each { |coin| coin_group_data2[coin] = { :sells => {}, :buys => {} } }
    bitorders.each{ |asset,bitbook|
      cg = coin_group_data2[$assets[asset][:coin]]
      bitbook.each{ |bitasset,book|
        book[:sells].each { |order|
          if not cg[:sells].has_key? order[:group]
            cg[:sells][order[:group]] = { :asset_amount => order[:asset_amount], :weight => order[:weight] }
          else
            cg[:sells][order[:group]][:asset_amount] += order[:asset_amount]
            cg[:sells][order[:group]][:weight] += order[:weight]
          end
        }
        book[:buys].each { |order|
          if not cg[:buys].has_key? order[:group]
            cg[:buys][order[:group]] = { :asset_amount => order[:asset_amount], :weight => order[:weight] }
          else
            cg[:buys][order[:group]][:asset_amount] += order[:asset_amount]
            cg[:buys][order[:group]][:weight] += order[:weight]
          end
        }
      }
    }
    coin_group_data2.each { |coin,cg|
      cap = $bitasset_market_reward_params[coin][:target_depth_per_group]
      cg[:sells].each{ |group,data|
        data[:score] = BigDecimal.new($group_reward_percent[group] * [1, Rational(data[:asset_amount], cap)].min, 20)
        daily_cg = daily_coin_group_data2[coin][:sells]
        if not daily_cg.has_key? group
          daily_cg[group] = { :score => data[:score] }
        else
          daily_cg[group][:score] += data[:score]
        end
      }
      cg[:buys].each{ |group,data|
        data[:score] = BigDecimal.new($group_reward_percent[group] * [1, Rational(data[:asset_amount], cap)].min, 20)
        daily_cg = daily_coin_group_data2[coin][:buys]
        if not daily_cg.has_key? group
          daily_cg[group] = { :score => data[:score] }
        else
          daily_cg[group][:score] += data[:score]
        end
      }
    }
    #puts coin_group_data2

    # order scores
    # BTS markets
    orders.each{ |asset,book|
      book[:sells].each { |order|
        coin = $assets[asset][:coin]
        cg_data = coin_group_data[coin] [:sells] [order[:group]]
        order[:score] = order[:weight] * cg_data[:score] / cg_data[:weight]
        if not daily_trader_scores[coin][:sells].has_key? order[:trader]
          daily_trader_scores[coin][:sells][order[:trader]] = order[:score]
        else
          daily_trader_scores[coin][:sells][order[:trader]] += order[:score]
        end
      }
      book[:buys].each { |order|
        coin = $assets[asset][:coin]
        cg_data = coin_group_data[coin] [:buys] [order[:group]]
        order[:score] = order[:weight] * cg_data[:score] / cg_data[:weight]
        if not daily_trader_scores[coin][:buys].has_key? order[:trader]
          daily_trader_scores[coin][:buys][order[:trader]] = order[:score]
        else
          daily_trader_scores[coin][:buys][order[:trader]] += order[:score]
        end
      }
    }
    #puts orders

    # bitasset markets
    bitorders.each{ |asset,bitbook|
      coin = $assets[asset][:coin]
      bitbook.each{ |bitasset,book|
        book[:sells].each { |order|
          cg_data = coin_group_data2[coin] [:sells] [order[:group]]
          order[:score] = order[:weight] * cg_data[:score] / cg_data[:weight]
          if not daily_trader_scores2[coin][:sells].has_key? order[:trader]
            daily_trader_scores2[coin][:sells][order[:trader]] = order[:score]
          else
            daily_trader_scores2[coin][:sells][order[:trader]] += order[:score]
          end
        }
        book[:buys].each { |order|
          cg_data = coin_group_data2[coin] [:buys] [order[:group]]
          order[:score] = order[:weight] * cg_data[:score] / cg_data[:weight]
          if not daily_trader_scores2[coin][:buys].has_key? order[:trader]
            daily_trader_scores2[coin][:buys][order[:trader]] = order[:score]
          else
            daily_trader_scores2[coin][:buys][order[:trader]] += order[:score]
          end
        }
      }
    }
    #puts bitorders

    #return #debug
  }

  puts "============================================="
  puts "Trader scores"
  puts daily_trader_scores
  puts daily_trader_scores2

  daily_coin_group_data.each { |coin,cg|
    cg[:sells].each{ |group,data|
      data[:reward] = ( data[:score] * $bts_market_daily_rewards[coin][:sells] / blocks ).to_i
    }
    cg[:buys].each{ |group,data|
      data[:reward] = ( data[:score] * $bts_market_daily_rewards[coin][:buys] / blocks ).to_i
    }
  }
  daily_coin_group_data2.each { |coin,cg|
    cg[:sells].each{ |group,data|
      data[:reward] = ( data[:score] * $bitasset_market_reward_params[coin][:sells] / blocks ).to_i
    }
    cg[:buys].each{ |group,data|
      data[:reward] = ( data[:score] * $bitasset_market_reward_params[coin][:buys] / blocks ).to_i
    }
  }
  puts "============================================="
  puts "Groups data"
  puts daily_coin_group_data
  puts daily_coin_group_data2

  total_reward = 0
  daily_trader_scores.each { |coin,sd|
    sd[:sells].each{ |trader,score|
      daily_trader_rewards[coin][:sells][trader] = ( score * $bts_market_daily_rewards[coin][:sells] / blocks ).to_i
      total_reward += daily_trader_rewards[coin][:sells][trader]
    }
    sd[:buys].each{ |trader,score|
      daily_trader_rewards[coin][:buys][trader] = ( score * $bts_market_daily_rewards[coin][:buys] / blocks ).to_i
      total_reward += daily_trader_rewards[coin][:buys][trader]
    }
  }
  daily_trader_scores2.each { |coin,sd|
    sd[:sells].each{ |trader,score|
      daily_trader_rewards2[coin][:sells][trader] = ( score * $bitasset_market_reward_params[coin][:sells] / blocks ).to_i
      total_reward += daily_trader_rewards2[coin][:sells][trader]
    }
    sd[:buys].each{ |trader,score|
      daily_trader_rewards2[coin][:buys][trader] = ( score * $bitasset_market_reward_params[coin][:buys] / blocks ).to_i
      total_reward += daily_trader_rewards2[coin][:buys][trader]
    }
  }
  puts
  puts "============================================="
  puts "Rewards"
  puts daily_trader_rewards
  puts daily_trader_rewards2
  puts
  puts "Total %0.5f BTS" % (total_reward.to_f/100000)
  puts

  daily_trader_rewards.each{ |coin,d|
    puts "============================================="
    puts "BTS / %s markets" % coin
    puts "--seller-------------------------reward(BTS)-"
    d[:sells].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      printf "%-30s%15.5f\n" % [acc,reward.to_f/100000]
    }
    puts "--buyer--------------------------reward(BTS)-"
    d[:buys].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      printf "%-30s%15.5f\n" % [acc,reward.to_f/100000]
    }
  }
  daily_trader_rewards2.each{ |coin,d|
    puts "============================================="
    puts "%s / bitasset markets" % coin
    puts "--seller-------------------------reward(BTS)-"
    d[:sells].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      printf "%-30s%15.5f\n" % [acc,reward.to_f/100000]
    }
    puts "--buyer--------------------------reward(BTS)-"
    d[:buys].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      printf "%-30s%15.5f\n" % [acc,reward.to_f/100000]
    }
  }

  transfer = 'add_operation_to_builder_transaction 0 [0,{"from":"1.2.100876","to":"%s","amount":{"amount":"%d","asset_id":"1.3.0"}}]'

  puts
  puts "============================================="
  puts "Commands"
  puts
  puts "begin_builder_transaction"
  daily_trader_rewards.each{ |coin,d|
    d[:sells].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      puts transfer % [acc,reward]
    }
    d[:buys].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      puts transfer % [acc,reward]
    }
  }
  daily_trader_rewards2.each{ |coin,d|
    d[:sells].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      puts transfer % [acc,reward]
    }
    d[:buys].sort_by{ |acc,reward| -reward }.each{ |acc,reward|
      next if reward < 1 # skip data < 0.00001 BTS
      puts transfer % [acc,reward]
    }
  }
  puts 'set_fees_on_builder_transaction 0 1.3.0'
  puts 'propose_builder_transaction2 0 %s "%sT23:55:00" 0 true' % [ $proposer, Date.today.next_day(10).to_s ]
  puts
end

# main
if __FILE__ == $0

  exit unless DATA.flock( File::LOCK_NB | File::LOCK_EX )

  current_date = $start_date
  while current_date <= $end_date
    path = File.join $snapshot_root_path, current_date.year.to_s, current_date.to_s

    process_snapshots( path, $score_output_path, current_date )

    current_date = current_date.next_day
  end

end
__END__

